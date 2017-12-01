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
require 'config'
require 'templater'
require 'constants'
require 'output'
require 'exceptions'
require 'command_helpers/node_identifier'

module Metalware
  module Commands
    class Build < CommandHelpers::BaseCommand
      GRACEFULLY_SHUTDOWN_KEY = :gracefully_shutdown
      COMPLETE_KEY = :complete

      private

      attr_reader :edit_start, :edit_continue

      delegate :template_path, to: :file_path
      delegate :in_gui?, to: Utils

      EDIT_SETUP_ERROR = 'Can not start and continue editing together'

      prepend CommandHelpers::NodeIdentifier

      def setup; end

      def run
        start_build
        wait_for_nodes_to_build
        teardown
      rescue
        # Ensure command is recorded as complete when in GUI.
        record_gui_build_complete if in_gui?
        raise
      end

      def dependency_hash
        {
          repo: repo_dependencies,
          configure: ['domain.yaml'],
          optional: {
            configure: ["groups/#{group&.name}.yaml"],
          },
        }
      end

      def repo_dependencies
        nodes.map(&:build_method).reduce([]) do |memo, bm|
          memo.push(bm.dependency_paths)
        end.flatten.uniq
      end

      def start_build
        nodes.each do |node|
          run_in_build_thread do
            node.build_method.start_hook
          end
        end
      end

      def build_threads
        @build_threads ||= []
      end

      def run_in_build_thread
        build_threads.push(Thread.new do
          begin
            yield
          rescue
            $stderr.puts $!.message
            $stderr.puts $!.backtrace
          end
        end)
      end

      def clear_up_build_threads
        build_threads.each(&:kill)
      end

      def wait_for_nodes_to_build
        Output.success 'Waiting for nodes to report as built...'
        Output.cli_only '(Ctrl-C to terminate)'

        rerendered_nodes = []
        loop do
          gracefully_shutdown if should_gracefully_shutdown?

          nodes.select do |node|
            !rerendered_nodes.include?(node) && built?(node)
          end
               .tap do |nodes|
            run_complete_hook(nodes)
            rerendered_nodes.push(*nodes)
          end
               .each do |node|
            Output.success "Node #{node.name} built."
          end

          all_nodes_reported_built = rerendered_nodes.length == nodes.length
          if all_nodes_reported_built
            # For now at least, keep thread alive when in GUI so can keep
            # accessing messages. XXX Change this, this is very wasteful.
            in_gui? ? record_gui_build_complete : break
          end

          sleep config.build_poll_sleep
        end
      end

      def built?(node)
        File.file?(file_path.build_complete(node.name))
      end

      def record_gui_build_complete
        Thread.current.thread_variable_set(COMPLETE_KEY, true)
      end

      def should_gracefully_shutdown?
        in_gui? && Thread.current.thread_variable_get(GRACEFULLY_SHUTDOWN_KEY)
      end

      def gracefully_shutdown
        # XXX Somewhat similar to `handle_interrupt`; may not be easily
        # generalizable however.
        Output.info 'Exiting...'
        run_all_complete_hooks
        teardown
        record_gui_build_complete
      end

      def run_all_complete_hooks
        run_complete_hook(nodes)
      end

      def run_complete_hook(nodes)
        nodes.each do |node|
          run_in_build_thread do
            node.build_method.complete_hook
          end
        end
      end

      def teardown
        clear_up_built_node_marker_files
        clear_up_build_threads
        Output.info 'Done.'
      end

      def clear_up_built_node_marker_files
        glob = File.join(config.built_nodes_storage_path, '*')
        files = Dir.glob(glob)
        FileUtils.rm_rf(files)
      end

      def handle_interrupt(_e)
        Output.info 'Exiting...'
        ask_if_should_rerender
        teardown
      rescue Interrupt
        Output.info 'Re-rendering templates anyway...'
        run_all_complete_hooks
        teardown
      end

      # Allows the input to be mocked
      def high_line
        @high_line ||= HighLine.new
      end

      delegate :agree, to: :high_line

      def ask_if_should_rerender
        should_rerender = <<-EOF.strip_heredoc
          Re-render appropriate templates for nodes as if build succeeded?
          [yes/no]
        EOF

        run_all_complete_hooks if agree(should_rerender)
      end

      EDIT_START_MSG = <<-EOF.strip_heredoc
        The build templates have been rendered and ready to be edited with `metal edit`
        Continue the build process with the `--edit-continue` flag
      EOF
    end
  end
end
