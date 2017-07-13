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
require 'templating/renderer'
require 'templating/repo_config_parser'


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

      raw_magic_namespace = Templating::MagicNamespace.new(
        config: metalware_config,
        node: node,
        **passed_magic_parameters
      )
      @magic_namespace = \
        Templating::MissingParameterWrapper.new(raw_magic_namespace)
      @passed_hash = parameters
      @config = Templating::RepoConfigParser.parse(base_config)
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

    delegate :replace_erb, to: Templating::Renderer

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
  end
end
