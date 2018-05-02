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
require 'data'
require 'staging'

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
      def render(namespace, template, **dynamic_namespace)
        raw_template = File.read(template)
        begin
          namespace.render_erb_template(raw_template, dynamic_namespace)
        rescue StandardError => e
          msg = "Failed to render template: #{template}"
          raise e, "#{msg}\n#{e}", e.backtrace
        end
      end

      def render_to_stdout(namespace, template, **dynamic_namespace)
        puts render(namespace, template, **dynamic_namespace)
      end

      def render_to_file(
        namespace,
        template,
        save_file,
        dynamic: {},
        &validation_block
      )
        rendered_template = render(namespace, template, **dynamic)

        rendered_template_valid?(
          rendered_template,
          &validation_block
        ).tap do |valid|
          if valid
            write_rendered_template(rendered_template, save_file: save_file)
          end
        end
      end

      private

      def rendered_template_valid?(rendered_template)
        # A rendered template is automatically valid, unless we're passed a
        # block which evaluates as falsy when given the rendered template.
        !block_given? || yield(rendered_template)
      end

      # TODO: Remove this once render_to_file method is removed
      def write_rendered_template(rendered_template, save_file:)
        File.open(save_file.chomp, 'w') do |f|
          f.puts rendered_template
        end
        MetalLog.info "Template Saved: #{save_file}"
      end
    end

    def initialize(staging)
      @staging = staging
    end

    def render(
      namespace,
      template,
      sync_location,
      dynamic: {},
      **staging_options
    )
      rendered = self.class.render(namespace, template, dynamic)
      staging.push_file(sync_location, rendered, **staging_options)
    end

    private

    attr_reader :staging
  end
end
