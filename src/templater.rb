# frozen_string_literal: true

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

require 'erb'
require 'active_support/core_ext/string/strip'

require 'constants'
require 'metal_log'
require 'exceptions'
require 'templating/iterable_recursive_open_struct'
require 'templating/missing_parameter_wrapper'
require 'templating/magic_namespace'
require 'templating/renderer'
require 'templating/repo_config_parser'

module Metalware
  class Templater
    MANAGED_FILE_MESSAGE = <<-EOF.strip_heredoc
    # This file is managed by Alces Metalware; any changes made to it directly
    # will be lost. You can change the data used to render it using the
    # `metal configure` commands.
    EOF

    class << self
      # XXX rename args in these methods - use `**parameters` for passing
      # template parameters?
      def render(config, template, **template_parameters)
        Templater.new(config, template_parameters).render(template)
      end

      def render_to_stdout(config, template, **template_parameters)
        puts render(config, template, template_parameters)
      end

      def render_to_file(
        config,
        template,
        save_file,
        prepend_managed_file_message: false,
        **template_parameters,
        &validation_block
      )
        rendered_template = render(config, template, template_parameters)
        if prepend_managed_file_message
          rendered_template = "#{MANAGED_FILE_MESSAGE}\n#{rendered_template}"
        end

        rendered_template_valid?(rendered_template, &validation_block).tap do |valid|
          write_rendered_template(rendered_template, save_file: save_file) if valid
        end
      end

      def render_and_append_to_file(config, template, append_file, **template_parameters)
        File.open(append_file.chomp, 'a') do |f|
          f.puts render(config, template, template_parameters)
        end
        MetalLog.info "Template Appended: #{append_file}"
      end

      private

      def rendered_template_valid?(rendered_template)
        # A rendered template is automatically valid, unless we're passed a
        # block which evaluates as falsy when given the rendered template.
        !block_given? || yield(rendered_template)
      end

      def write_rendered_template(rendered_template, save_file:)
        File.open(save_file.chomp, 'w') do |f|
          f.puts rendered_template
        end
        MetalLog.info "Template Saved: #{save_file}"
      end
    end

    attr_reader :config

    # XXX Have this just take allowed keyword parameters:
    # - nodename
    # - index
    # - what else?
    def initialize(metalware_config, parameters = {})
      @config = Templating::RepoConfigParser.parse_for_node(
        node_name: parameters[:nodename],
        config: metalware_config,
        additional_parameters: parameters
      )
    end

    def render(template)
      File.open(template.chomp, 'r') do |f|
        replace_erb(f.read, @config)
      end
    end

    def render_from_string(str)
      replace_erb(str, @config)
    end

    delegate :replace_erb, to: Templating::Renderer
  end
end
