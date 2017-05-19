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
require 'recursive-open-struct'
require 'active_support/core_ext/hash/keys'

require "constants"
require 'nodeattr_interface'
# require "alces/stack/log"

module Metalware
  module Templater
    class Handler
      # XXX Make this use the Combiner rather than be a superclass of it, to
      # better separate these.
      # XXX Have method to print template here, and do not expose access to
      # `file` method directly, so can cleanly stub this for testing.
      # XXX need `template_parameters` param? Child class, which is only one
      # used (outside of tests), forbids this.
      # XXX rename to `render`; rename other methods here appropriately too.
      def file(filename, template_parameters={})
        File.open(filename.chomp, 'r') do |f|
          replace_erb(f.read, template_parameters)
        end
      end

      def save(template_file, save_file, template_parameters={})
        File.open(save_file.chomp, "w") do |f|
          f.puts file(template_file, template_parameters)
        end
        # Alces::Stack::Log.info "Template Saved: #{save_file}"
      end

      def append(template_file, append_file, template_parameters={})
        File.open(append_file.chomp, 'a') do |f|
          f.puts file(template_file, template_parameters)
        end
        # Alces::Stack::Log.info "Template Appended: #{append_file}"
      end

      def replace_erb(template, template_parameters)
        parameters_binding = template_parameters.instance_eval {binding}
        ERB.new(template).result(parameters_binding)
      rescue StandardError => e
        $stderr.puts "Could not parse ERB"
        $stderr.puts template.to_s
        $stderr.puts template_parameters.to_s
        raise e
      end
    end

    class Combiner < Handler
      attr_reader :config

      # XXX Have this just take allowed keyword parameters:
      # - nodename
      # - index
      # - what else?
      def initialize(hash={})
        passed_magic_parameters = hash.select do |k,v|
          [:index, :nodename, :firstboot].include?(k) && !v.nil?
        end
        @magic_namespace = MagicNamespace.new(passed_magic_parameters)
        @passed_hash = hash
        @config = parse_config
      end

      def file(filename, template={})
        raise HashInputError if !template.empty?
        super(filename, @config)
      end

      # XXX Make these not nested classes, also possibly should use common
      # error class or superclass for these.
      class HashInputError < StandardError
        def initialize(msg="Hash included through file method. Must be included in Combiner initializer")
          super
        end
      end

      class LoopErbError < StandardError
        def initialize(msg="Input hash may contain infinitely recursive ERB")
          super
        end
      end

      private

      def nodename
        @magic_namespace.nodename
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
            config_path = "#{Constants::REPO_PATH}/config/#{config_name}.yaml"
            config = YAML.load_file(config_path)
          rescue Errno::ENOENT # Skips missing files
          rescue StandardError => e
            $stderr.puts "Could not parse YAML config file"
            raise e
          else
            if !config.is_a? Hash
              raise "Expected YAML config file to contain a hash"
            else
              combined_configs.merge!(config)
            end
          end
        end
        # XXX only symbolizes top-level keys, but not those in nested hashes =>
        # confusing.
        combined_configs.symbolize_keys
      end

      def ordered_node_config_files
        list = [ "all" ]
        return list if !nodename
        list_str = `nodeattr -l #{nodename} 2>/dev/null`.chomp
        if list_str.empty? then return list end
        list.concat(list_str.split(/\n/).reverse)
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

        RecursiveOpenStruct.new(current_parsed_config)
      end

      def perform_config_parsing_pass(current_parsed_config)
        current_parsed_config.map do |k,v|
          [k, parse_config_value(v, current_parsed_config)]
        end.to_h
      end

      def parse_config_value(value, current_parsed_config)
        case value
        when String
          replace_erb(value, RecursiveOpenStruct.new(current_parsed_config))
        when Hash
          value.map do |k,v|
            [k, parse_config_value(v, current_parsed_config)]
          end.to_h
        else
          value
        end
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

    MagicNamespace = Struct.new(:index, :nodename, :firstboot) do
      def initialize(index: 0, nodename: nil, firstboot: nil)
        super(index, nodename, firstboot)
      end

      def genders
        GenderGroupProxy
      end

      def hunter
        YAML.load_file(Constants::HUNTER_PATH).map do |node_config|
          OpenStruct.new(node_config)
        end
      rescue Errno::ENOENT
        # XXX Should warn/log that resorting to this?
        []
      end

      def hosts_url
        system_file_url 'hosts'
      end

      def genders_url
        system_file_url 'genders'
      end

      def build_complete_url
        if nodename
          deployment_server_url "exec/kscomplete.php?name=#{nodename}"
        end
      end

      def hostip
        hostip = `#{determine_hostip_script}`.chomp
        if $?.success?
          hostip
        else
          # If script failed for any reason fall back to using `hostname -i`,
          # which may or may not give the IP on the interface we actually want
          # to use (note: the dance with pipes is so we only get the last word
          # in the output, as I've had the IPv6 IP included first before, which
          # breaks all the things).
          # XXX Warn about falling back to this?
          `hostname -i | xargs -d' ' -n1 | tail -n 2 | head -n 1`.chomp
        end
      end

      private

      def system_file_url(system_file)
        deployment_server_url "system/#{system_file}"
      end

      def deployment_server_url(url_path)
        "http://#{hostip}/#{url_path}"
      end

      def determine_hostip_script
        File.join(
          Constants::METALWARE_INSTALL_PATH,
          'libexec/determine-hostip'
        )
      end
    end
  end
end
