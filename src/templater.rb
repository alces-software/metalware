#==============================================================================
# Copyright (C) 2017 Stephen F. Norledge and Alces Software Ltd.
#
# This file/package is part of Alces Metalware.
#
# Alces Metalware is free software: you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License
# as published by the Free Software Foundation, either version 3 of
# the License, or (at your option) any later version.
#
# Alces Metalware is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this package.  If not, see <http://www.gnu.org/licenses/>.
#
# For more information on the Alces Metalware, please visit:
# https://github.com/alces-software/metalware
#==============================================================================
require "erb"
require "ostruct"
require "yaml"
require 'active_support/core_ext/hash'
require 'hashie'

require "constants"
require 'nodeattr_interface'
require 'metal_log'
require 'deployment_server'
require 'exceptions'
require 'iterable_recursive_open_struct'

module Metalware
  class MissingParameterWrapper
    def initialize(wrapped_obj)
      @missing_tags = []
      @wrapped_obj = wrapped_obj
    end

    def method_missing(s, *a, &b)
      value = @wrapped_obj.send(s)
      if value.nil? && ! @missing_tags.include?(s)
        @missing_tags.push s
        MetalLog.warn "Unset template parameter: #{s}"
      end
      value
    end

    def [](a)
      # ERB expects to be able to index in to the binding passed; this should
      # function the same as a method call.
      send(a)
    end
  end

  class Templater
    class << self
      # XXX rename args in these methods - use `**parameters` for passing
      # template parameters?
      def render(config, template, template_parameters={})
        Templater.new(config, template_parameters).render(template)
      end

      def render_to_stdout(config, template, template_parameters={})
        puts render(config, template, template_parameters)
      end

      def render_to_file(config, template, save_file, template_parameters={})
        File.open(save_file.chomp, "w") do |f|
          f.puts render(config, template, template_parameters)
        end
        MetalLog.info "Template Saved: #{save_file}"
      end

      def render_and_append_to_file(config, template, append_file, template_parameters={})
        File.open(append_file.chomp, 'a') do |f|
          f.puts render(config, template, template_parameters)
        end
        MetalLog.info "Template Appended: #{append_file}"
      end
    end

    attr_reader :config
    attr_reader :nodename

    # XXX Have this just take allowed keyword parameters:
    # - nodename
    # - index
    # - what else?
    def initialize(metalware_config, parameters={})
      @metalware_config = metalware_config
      @nodename = parameters[:nodename]

      passed_magic_parameters = parameters.select do |k,v|
        [:index, :nodename, :firstboot, :files].include?(k) && !v.nil?
      end
      magic_struct = MagicNamespace.new(passed_magic_parameters)
      @magic_namespace = MissingParameterWrapper.new(magic_struct)
      @passed_hash = parameters
      @config = parse_config
    end

    def render(template)
      File.open(template.chomp, 'r') do |f|
        replace_erb(f.read, @config)
      end
    end

    def render_from_string(str)
      replace_erb(str, @config)
    end

    # XXX Make this not a nested class, also possibly should use common error
    # class or superclass.
    class LoopErbError < StandardError
      def initialize(msg="Input hash may contain infinitely recursive ERB")
        super
      end
    end

    private

    def replace_erb(template, template_parameters)
      parameters_binding = template_parameters.instance_eval {binding}
      render_erb_template(template, parameters_binding)
    rescue NoMethodError => e
      # May be useful to include the name of the unset parameter in this error,
      # however this is tricky as by the time we attempt to access a method on
      # it the unset parameter is just `nil` as far as we can see here.
      raise UnsetParameterAccessError,
        "Attempted to call method `#{e.name}` of unset template parameter"
    end

    def render_erb_template(template, binding)
      # This mode allows templates to prevent inserting a newline for a given
      # line by ending the ERB tag on that line with `-%>`.
      trim_mode = '-'

      safe_level = 0
      ERB.new(template, safe_level, trim_mode).result(binding)
    end

    # The merging of the raw combined config files, any additional passed
    # values, and the magic `alces` namespace; this is the config prior to
    # parsing any nested ERB values.
    def base_config
      @base_config ||= raw_config
        .merge(@passed_hash)
        .merge(alces: @magic_namespace)
    end

    def raw_config
      combined_configs = {}
      ordered_node_config_files.each do |config_name|
        begin
          config_path = "#{@metalware_config.repo_path}/config/#{config_name}.yaml"
          config = YAML.load_file(config_path)
        rescue Errno::ENOENT # Skips missing files
        rescue StandardError => e
          $stderr.puts "Could not parse YAML config file"
          raise e
        else
          if !config.is_a? Hash
            raise "Expected YAML config file to contain a hash"
          else
            combined_configs.deep_merge!(config)
          end
        end
      end
      combined_configs.deep_transform_keys{ |k| k.to_sym }
    end

    def ordered_node_config_files
      list = [ "all" ]
      return list if !nodename
      list.concat(NodeattrInterface.groups_for_node(nodename).reverse)
      list.push(nodename)
      list.uniq
    end

    def parse_config
      current_parsed_config = base_config
      current_config_string = current_parsed_config.to_s
      previous_config_string = nil
      count = 0

      # Loop through the config and recursively parse any config values which
      # contain ERB, until the parsed config is not changing or we have
      # exceeded the maximum number of passes to make.
      while previous_config_string != current_config_string
        count += 1
        raise LoopErbError if count > Constants::MAXIMUM_RECURSIVE_CONFIG_DEPTH

        previous_config_string = current_config_string
        current_parsed_config = perform_config_parsing_pass(current_parsed_config)
        current_config_string = current_parsed_config.to_s
      end

      create_template_parameters(current_parsed_config)
    end

    def perform_config_parsing_pass(current_parsed_config)
      current_parsed_config.map do |k,v|
        [k, parse_config_value(v, current_parsed_config)]
      end.to_h
    end

    def parse_config_value(value, current_parsed_config)
      case value
      when String
        parameters = create_template_parameters(current_parsed_config)
        replace_erb(value, parameters)
      when Hash
        value.map do |k,v|
          [k, parse_config_value(v, current_parsed_config)]
        end.to_h
      else
        value
      end
    end

    def create_template_parameters(config)
      MissingParameterWrapper.new(IterableRecursiveOpenStruct.new(config))
    end
  end

  module GenderGroupProxy
    class << self
      def method_missing(group_symbol)
        NodeattrInterface.nodes_in_group(group_symbol)
      rescue NoGenderGroupError
        # XXX Should warn/log that resorting to this? Here or in
        # `MagicNamespace`?
        []
      end
    end
  end

  MagicNamespace = Struct.new(:index, :nodename, :firstboot, :files) do
    def initialize(index: 0, nodename: nil, firstboot: nil, files: nil)
      files = Hashie::Mash.new(files) if files
      super(index, nodename, firstboot, files)
    end

    def genders
      # XXX Do we want to make genders available as a `Hashie::Mash` too?
      # Depends if we want to be able to iterate through genders or just get
      # list of nodes in a specified gender
      GenderGroupProxy
    end

    def hunter
      if File.exist? Constants::HUNTER_PATH
        Hashie::Mash.load(Constants::HUNTER_PATH)
      else
        # XXX Should warn/log that resorting to this?
        Hashie::Mash.new
      end
    end

    def hosts_url
      DeploymentServer.system_file_url 'hosts'
    end

    def genders_url
      DeploymentServer.system_file_url 'genders'
    end

    def kickstart_url
      DeploymentServer.kickstart_url(nodename)
    end

    def build_complete_url
      DeploymentServer.build_complete_url(nodename)
    end

    def hostip
      DeploymentServer.ip
    end
  end
end
