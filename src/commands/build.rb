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
require 'node'
require 'nodes'
require 'output'
require 'build_files_retriever'

module Metalware
  module Commands
    class Build < CommandHelpers::BaseCommand
      private

      attr_reader :options, :group_name, :nodes

      def setup(args, options)
        @options = options
        node_identifier = args.first
        @group_name = node_identifier if options.group
        @nodes = Nodes.create(config, node_identifier, options.group)
      end

      def run
        render_build_templates
        wait_for_nodes_to_build
        teardown
      end

      def dependency_hash
        {
          repo: repo_dependencies,
          configure: ['domain.yaml'],
          optional: {
            configure: ["groups/#{group_name}.yaml"],
          },
        }
      end

      def repo_dependencies
        nodes.map do |node|
          [:pxelinux, :kickstart].map do |template_type|
            full_template_path = template_path(template_type, node: node)
            file_path.repo_relative_path_to(full_template_path)
          end
        end.flatten.uniq
      end

      def render_build_templates
        nodes.template_each firstboot: true do |parameters, node|
          parameters[:files] = build_files(node)
          render_build_files(parameters, node)
          render_build_method_templates(parameters, node)
        end
      end

      def build_files(node)
        # Cache the build files as retrieved for each node so don't need to
        # re-retrieve each time; in particular we don't want to re-make any
        # network requests for files specified by a URL.
        @build_files ||= {}
        @build_files[node.name] ||= retrieve_build_files(node)
      end

      def retrieve_build_files(node)
        retriever = BuildFilesRetriever.new(node.name, config)
        retriever.retrieve(node.build_files)
      end

      def render_build_files(parameters, node)
        build_files(node).each do |namespace, files|
          files.each do |file|
            next if file[:error]
            render_path = node.rendered_build_file_path(namespace, file[:name])
            FileUtils.mkdir_p(File.dirname(render_path))
            Templater.render_to_file(config, file[:template_path], render_path, parameters)
          end
        end
      end

      def render_build_method_templates(parameters, node)
        if basic_build_node?(node)
          render_basic(parameters, node)
        else
          render_kickstart(parameters, node)
          render_pxelinux(parameters, node)
        end
      end

      def render_basic(parameters, node)
        render_build_method_template(
          :basic, parameters: parameters, node: node
        )
      end

      def render_kickstart(parameters, node)
        render_build_method_template(
          :kickstart, parameters: parameters, node: node
        )
      end

      def render_pxelinux(parameters, node)
        # XXX handle nodes without hexadecimal IP, i.e. nodes not in `hosts`
        # file yet - best place to do this may be when creating `Node` objects?
        save_path = File.join(config.pxelinux_cfg_path, node.hexadecimal_ip)
        render_build_method_template(
          :pxelinux,
          parameters: parameters,
          node: node,
          save_path: save_path
        )
      end

      def render_build_method_template(template_type, parameters:, node:, save_path: nil)
        template_type_path = template_path template_type, node: node
        save_path ||= File.join(
          config.rendered_files_path, template_type.to_s, node.name
        )
        Templater.render_to_file(config, template_type_path, save_path, parameters)
      end

      def template_path(template_type, node:)
        File.join(
          config.repo_path,
          template_type.to_s,
          template_file_name(template_type, node: node)
        )
      end

      def template_file_name(template_type, node:)
        repo_template(template_type, node: node) ||
          'default'
      end

      def repo_template(template_type, node:)
        repo_specified_templates = node.repo_config[:templates] || {}
        repo_specified_templates[template_type]
      end

      def basic_build_node?(node)
        build_method = node.repo_config[:build_method]
        build_method == 'basic'
      end

      def wait_for_nodes_to_build
        Output.stderr 'Waiting for nodes to report as built...',
                      '(Ctrl-C to terminate)'

        rerendered_nodes = []
        loop do
          nodes.select do |node|
            !rerendered_nodes.include?(node) && node.built?
          end
               .tap do |nodes|
            render_permanent_pxelinux_configs(nodes)
            rerendered_nodes.push(*nodes)
          end
               .each do |node|
            Output.stderr "Node #{node.name} built."
          end

          all_nodes_reported_built = rerendered_nodes.length == nodes.length
          break if all_nodes_reported_built

          sleep config.build_poll_sleep
        end
      end

      def render_all_permanent_pxelinux_configs
        render_permanent_pxelinux_configs(nodes)
      end

      def render_permanent_pxelinux_configs(nodes)
        nodes.template_each firstboot: false do |parameters, node|
          # Only nodes with a 'kickstart' build method (the default) must have
          # PXELINUX templates re-rendered.
          unless basic_build_node?(node)
            parameters[:files] = build_files(node)
            render_pxelinux(parameters, node)
          end
        end
      end

      def teardown
        clear_up_built_node_marker_files
        Output.stderr 'Done.'
      end

      def clear_up_built_node_marker_files
        glob = File.join(config.built_nodes_storage_path, '*')
        files = Dir.glob(glob)
        FileUtils.rm_rf(files)
      end

      def handle_interrupt(_e)
        Output.stderr 'Exiting...'
        ask_if_should_rerender_pxelinux_configs
        teardown
      rescue Interrupt
        Output.stderr 'Re-rendering all permanent PXELINUX templates anyway...'
        render_all_permanent_pxelinux_configs
        teardown
      end

      def ask_if_should_rerender_pxelinux_configs
        should_rerender = <<-EOF.strip_heredoc
          Re-render permanent PXELINUX templates for all nodes as if build succeeded?
          [yes/no]
        EOF
        render_all_permanent_pxelinux_configs if agree(should_rerender)
      end
    end
  end
end
