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
require 'build_files_retriever'
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

      def setup
        @edit_start = options.edit_start
        @edit_continue = options.edit_continue
        raise EditModeError, EDIT_SETUP_ERROR if edit_start && edit_continue
      end

      def run
        render_build_templates unless edit_continue
        if edit_start
          puts(EDIT_START_MSG)
          return
        end
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
        build_methods.reduce([]) do |memo, (_name, build_method)|
          memo.push(build_method.template_paths)
        end.flatten.uniq
      end

      def build_methods
        @build_methods = begin
          nodes.reduce({}) do |memo, node|
            memo.merge(node.name => node.build_method.new(config, node))
          end
        end
      end

      def render_build_templates
        nodes.each do |node|
          render_build_files(node)
          build_method = build_methods[node.name]
          build_method.render_build_start_templates
        end
      end

      def render_build_files(node)
        node.files.each do |namespace, files|
          files.each do |file|
            next if file[:error]
            render_path = file_path.rendered_build_file_path(node.name, namespace, file[:name])
            FileUtils.mkdir_p(File.dirname(render_path))
            Templater.render_to_file(node, file[:template_path], render_path)
          end
        end
      end

      def start_build
        nodes.each do |node|
          build_threads.add(Thread.new { node.start_build })
        end
      end

      def build_threads
        @build_threads ||= ThreadGroup.new
      end

      def clear_up_build_threads
        build_threads.list.map(&:kill)
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
            render_build_complete_templates(nodes)
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
        render_all_build_complete_templates
        teardown
        record_gui_build_complete
      end

      def render_all_build_complete_templates
        render_build_complete_templates(nodes)
      end

      def render_build_complete_templates(nodes)
        nodes.each do |node|
          build_method = build_methods[node.name]
          build_method.render_build_complete_templates
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
        render_all_build_complete_templates
        teardown
      end

      def ask_if_should_rerender
        should_rerender = <<-EOF.strip_heredoc
          Re-render appropriate templates for nodes as if build succeeded?
          [yes/no]
        EOF
        render_all_build_complete_templates if agree(should_rerender)
      end

      EDIT_START_MSG = <<-EOF.strip_heredoc
        The build templates have been rendered and ready to be edited with `metal edit`
        Continue the build process with the `--edit-continue` flag
      EOF
    end
  end
end
