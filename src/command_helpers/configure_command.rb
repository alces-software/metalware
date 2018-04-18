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

require 'command_helpers/base_command'
require 'configurator'
require 'active_support/core_ext/string/strip'
require 'render_methods'
require 'staging'

module Metalware
  module CommandHelpers
    class ConfigureCommand < BaseCommand
      private

      GENDERS_INVALID_MESSAGE = <<-EOF.strip_heredoc
        You should be able to fix this error by re-running the `configure`
        command and correcting the invalid input, or by manually editing the
        appropriate answers file or template and using the `configure rerender`
        command to re-render the templates.
      EOF

      def run
        configurator.configure(answers)
        custom_configuration
        render_genders
      end

      def answers
        if options.answers
          JSON.parse(options.answers).deep_transform_keys(&:to_sym)
        end
      rescue StandardError => e
        err = AnswerJSONSyntax.new('An error occurred parsing the answer JSON')
        err.set_backtrace(e.backtrace)
        raise err
      end

      def handle_interrupt(_e)
        abort 'Exiting without saving...'
      end

      def custom_configuration
        # Custom additional configuration for a `configure` command, if any,
        # should be performed in this method in subclasses.
      end

      def answer_file
        raise NotImplementedError
      end

      def relative_answer_file
        answer_file.sub("#{FilePath.answer_files}/", '')
      end

      def dependency_hash
        {
          repo: ['configure.yaml'],
          optional: {
            configure: [relative_answer_file],
          },
        }
      end

      def configurator
        raise NotImplementedError
      end

      def render_genders
        # The genders file must be templated with a new namespace object as the
        # answers may have changed since they where loaded
        new_alces = Namespaces::Alces.new
        Staging.template do |templater|
          RenderMethods::Genders.render_to_staging(new_alces, templater)
        end
      end
    end
  end
end
