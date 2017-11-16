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

require 'active_support/core_ext/string/strip'
require 'active_support/core_ext/string/filters'

require 'constants'
require 'metal_log'
require 'exceptions'
require 'utils'
require 'file_path'

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
      def render(alces, template, **dynamic_namespace)
        raw_template = File.read(template)
        begin
          alces.render_erb_template(raw_template, dynamic_namespace)
        rescue => e
          msg = "Failed to render template: #{template}"
          raise e, "#{msg}\n#{e}", e.backtrace
        end
      end

      def render_to_stdout(alces, template, **dynamic_namespace)
        puts render(alces, template, **dynamic_namespace)
      end

      def render_to_file(
        alces,
        template,
        save_file,
        prepend_managed_file_message: false,
        **dynamic_namespace,
        &validation_block
      )
        rendered_template = render(alces, template, **dynamic_namespace)
        if prepend_managed_file_message
          rendered_template = "#{MANAGED_FILE_MESSAGE}\n#{rendered_template}"
        end

        rendered_template_valid?(
          rendered_template,
          &validation_block
        ).tap do |valid|
          if valid
            write_rendered_template(rendered_template, save_file: save_file)
          end
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
      def render_managed_file(alces, template, managed_file, &validation_block)
        rendered_template = render(alces, template)
        rendered_template_valid?(
          rendered_template,
          &validation_block
        ).tap do |valid|
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
        new_managed_file = [pre,
                            managed_section(rendered_template.strip),
                            post].join
        write_rendered_template(new_managed_file, save_file: managed_file)
      end

      def current_file_contents(file)
        File.exist?(file) ? File.read(file).strip : ''
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

      # TODO: Remove this once render_to_file method is removed
      def write_rendered_template(rendered_template, save_file:)
        File.open(save_file.chomp, 'w') do |f|
          f.puts rendered_template
        end
        MetalLog.info "Template Saved: #{save_file}"
      end
    end

    def initialize(metal_config)
      @metal_config = metal_config
    end

    def render_to_staging(
      alces,
      template,
      save_file,
      managed: false,
      dynamic: {},
      &validate
    )
      rendered_template = self.class.render(alces, template, dynamic)
      staging_file = file_path.staging(save_file)

      validate_and_write_file(rendered_template, staging_file, &validate)
    end

    private

    attr_reader :metal_config

    def file_path
      @file_path ||= FilePath.new(metal_config)
    end

    def validate_and_write_file(content, save_file, &validate)
      # Ensures a validation block is defined
      validate = ->(_t) { true } unless block_given?

      validate.call(content).tap do |valid|
        if valid
          File.write(save_file, content)
          MetalLog.info "Template Saved: #{save_file}"
        end
      end
    end
  end
end
