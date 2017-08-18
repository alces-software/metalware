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
require 'utils'
require 'templating/iterable_recursive_open_struct'
require 'templating/magic_namespace'
require 'templating/renderer'
require 'templating/configuration'
require 'binding'

module Metalware
  class Templater
    MANAGED_FILE_MESSAGE = <<-EOF.strip_heredoc
    # This file is managed by Alces Metalware; any changes made to it directly
    # will be lost. You can change the data used to render it using the
    # `metal configure` commands.
    EOF

    MANAGED_START_MARKER = 'METALWARE_START'
    MANAGED_START = "########## #{MANAGED_START_MARKER} ##########"
    MANAGED_END_MARKER = 'METALWARE_END'
    MANAGED_END = "########## #{MANAGED_END_MARKER} ##########"
    MANAGED_COMMENT = Utils.commentify(
      <<-EOF.squish
      This section of this file is managed by Alces Metalware. Any changes made
      to this file between the #{MANAGED_START_MARKER} and
      #{MANAGED_END_MARKER} markers may be lost; you should make any changes
      you want to persist outside of this section or to the template directly.
    EOF
    )

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

      # Render template to a file where only part of the file is managed by
      # Metalware:
      # - if the file does not exist yet, it will be created with a new managed
      # section;
      # - if it exists without a managed section, the new section will be
      # appended to the bottom of the current file;
      # - if it exists with a managed section, this section will be replaced
      # with the new managed section.
      def render_managed_file(config, template, managed_file, &validation_block)
        rendered_template = render(config, template)
        rendered_template_valid?(rendered_template, &validation_block).tap do |valid|
          update_managed_file(managed_file, rendered_template) if valid
        end
      end

      private

      def rendered_template_valid?(rendered_template)
        # A rendered template is automatically valid, unless we're passed a
        # block which evaluates as falsy when given the rendered template.
        !block_given? || yield(rendered_template)
      end

      def update_managed_file(managed_file, rendered_template)
        pre, post = split_on_managed_section(
          current_file_contents(managed_file)
        )
        new_managed_file = [pre, managed_section(rendered_template.strip), post].join
        write_rendered_template(new_managed_file, save_file: managed_file)
      end

      def current_file_contents(file)
        if File.exist?(file)
          File.read(file).strip
        else
          ''
        end
      end

      def split_on_managed_section(file_contents)
        if file_contents.include? MANAGED_START
          pre, rest = file_contents.split(MANAGED_START)
          _, post = rest.split(MANAGED_END)
          [pre, post]
        else
          [file_contents + "\n\n", nil]
        end
      end

      def managed_section(rendered_template)
        [
          MANAGED_START,
          MANAGED_COMMENT,
          rendered_template,
          MANAGED_END,
        ].join("\n") + "\n"
      end

      def write_rendered_template(rendered_template, save_file:)
        File.open(save_file.chomp, 'w') do |f|
          f.puts rendered_template
        end
        MetalLog.info "Template Saved: #{save_file}"
      end
    end

    # XXX Have this just take allowed keyword parameters:
    # - nodename
    # - index
    # - what else?
    def initialize(metalware_config, parameters_input = {})
      @config = metalware_config
      @parameters = parameters_input
    end

    def render(template)
      File.open(template.chomp, 'r') do |f|
        replace_erb(f.read, binding)
      end
    end

    def render_from_string(str)
      replace_erb(str, binding)
    end

    # Only use this for the view method, otherwise it is slow
    # If you need a value, query the Binding::Parameter directly
    def repo_config
      eval(render_from_string(raw_repo_config_str))
    end

    delegate :replace_erb, to: Templating::Renderer

    private

    attr_reader :config, :parameters

    def binding
      Binding.build(config, node_name, magic_parameter: magic_parameters)
    end

    def magic_parameters
      parameters.select do |k, v|
        [:firstboot, :files].include?(k) && !v.nil?
      end
    end

    def node_name
      parameters[:nodename]
    end

    def raw_repo_config_str
      Templating::Configuration.for_node(node_name, config: config)
                               .raw_config
                               .to_s
    end

    # Used in testing
    def magic_namespace
      Binding.build_no_wrapper(config, node_name, magic_parameter: magic_parameters)
             .send(:alces_namespace)
    end
  end
end
