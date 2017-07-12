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

require "constants"
require 'metal_log'
require 'exceptions'
require 'templating/iterable_recursive_open_struct'
require 'templating/missing_parameter_wrapper'
require 'templating/magic_namespace'


module Metalware
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
      passed_magic_parameters = parameters.select { |k,v|
          [:firstboot, :files].include?(k) && !v.nil?
      }

      magic_struct = Templating::MagicNamespace.new(**passed_magic_parameters, node: node)
      @magic_namespace = Templating::MissingParameterWrapper.new(magic_struct)
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
      erb = ERB.new(template, safe_level, trim_mode)

      begin
        erb.result(binding)
      rescue SyntaxError => error
        handle_error_rendering_erb(template, error)
      end
    end

    def handle_error_rendering_erb(template, error)
      Output.stderr "\nRendering template failed!\n\n"
      Output.stderr "Template:\n\n"
      Output.stderr_indented_error_message template
      Output.stderr "\nError message:\n\n"
      Output.stderr_indented_error_message error.message
      abort
    end

    # The merging of the raw combined config files, any additional passed
    # values, and the magic `alces` namespace; this is the config prior to
    # parsing any nested ERB values.
    # XXX Get rid of merging in `passed_hash`? This will cause an issue if a
    # config specifies a value with the same name as something in the
    # `passed_hash`, as it will overshadow it, and we don't actually want to
    # support this any more.
    def base_config
      @base_config ||= node.raw_config
        .merge(@passed_hash)
        .merge(alces: @magic_namespace)
    end

    def node
      @node ||= Node.new(@metalware_config, nodename)
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
        if count > Constants::MAXIMUM_RECURSIVE_CONFIG_DEPTH
          raise RecursiveConfigDepthExceededError
        end

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
      Templating::MissingParameterWrapper.new(
        Templating::IterableRecursiveOpenStruct.new(config)
      )
    end
  end
end
