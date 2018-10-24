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

require 'command_helpers/base_command'
require 'constants'
require 'underware/output'
require 'exceptions'
require 'underware/command_helpers/node_identifier'
require 'build_event'

module Metalware
  module Commands
    class Build < CommandHelpers::BaseCommand
      private

      delegate :template_path, to: :file_path
      delegate :agree, to: :high_line

      attr_reader :build_event

      prepend Underware::CommandHelpers::NodeIdentifier

      def setup
        @build_event = BuildEvent.new(nodes)
      end

      def run
        Underware::Output.success 'Waiting for nodes to report as built...'
        Underware::Output.stderr '(Ctrl-C to terminate)'

        build_event.run_start_hooks

        until build_event.build_complete?
          # TODO: Split process up more should go in here
          build_event.process
          sleep Constants::BUILD_POLL_SLEEP
        end

        teardown
      end

      def dependency_hash
        {
          repo: repo_dependencies,
          configure: ['domain.yaml'],
        }
      end

      def repo_dependencies
        nodes.map do |node|
          BuildMethods.build_method_for(node)
        end.reduce([]) do |memo, bm|
          memo.push(bm.dependency_paths)
        end.flatten.uniq
      end

      def teardown
        clear_up_built_node_marker_files
        build_event.kill_threads
        Underware::Output.info 'Done.'
      end

      def clear_up_built_node_marker_files
        nodes.each do |node|
          FileUtils.rm_rf(node.build_complete_path)
        end
      end

      def handle_interrupt(_e)
        Underware::Output.info 'Exiting...'
        ask_if_should_run_build_complete
        teardown
      rescue Interrupt
        Underware::Output.info 'Re-rendering templates anyway...'
        build_event.run_all_complete_hooks
        teardown
      end

      # Allows the input to be mocked
      def high_line
        @high_line ||= HighLine.new
      end

      def ask_if_should_run_build_complete
        should_rerender = <<-EOF.strip_heredoc
          Run the complete_hook for nodes as if build succeeded?
          [yes/no]
        EOF

        build_event.run_all_complete_hooks if agree(should_rerender)
      end
    end
  end
end
