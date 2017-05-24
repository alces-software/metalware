
require 'active_support/core_ext/string/strip'

require 'commands/base_command'
require 'config'
require 'templater'
require 'constants'
require 'node'
require 'nodes'
require 'iterator'
require 'output'


module Metalware
  module Commands
    class Build < BaseCommand

      private

      def setup(args, options)
        options.default \
          kickstart: 'default',
          pxelinux: 'default'
        @options = options
        @config = 
        node_identifier = args.first
        @nodes = Nodes.create(@config, node_identifier, options.group)
      end

      def run
        render_build_templates
        wait_for_nodes_to_build
        teardown
      end

      def render_build_templates
        @nodes.template_each firstboot: true do |parameters, node|
          render_kickstart(parameters, node)
          render_pxelinux(parameters, node)
        end
      end

      def render_kickstart(parameters, node)
        kickstart_template_path = template_path :kickstart
        # XXX Ensure this path has been created
        kickstart_save_path = File.join(
          @config.rendered_files_path, 'kickstart', node.name
        )
        Templater.render_to_file(kickstart_template_path, kickstart_save_path, parameters)
      end

      def render_pxelinux(parameters, node)
        # XXX handle nodes without hexadecimal IP, i.e. nodes not in `hosts`
        # file yet - best place to do this may be when creating `Node` objects?
        pxelinux_template_path = template_path :pxelinux
        pxelinux_save_path = File.join(
          @config.pxelinux_cfg_path, node.hexadecimal_ip
        )
        Templater.render_to_file(pxelinux_template_path, pxelinux_save_path, parameters)
      end

      def template_path(template_type)
        File.join(
          @config.repo_path,
          template_type.to_s,
          @options.__send__(template_type)
        )
      end

      def wait_for_nodes_to_build
        Output.stderr 'Waiting for nodes to report as built...',
          '(Ctrl-C to terminate)'

        rerendered_nodes = []
        loop do
          @nodes.select do |node|
            !rerendered_nodes.include?(node) && node.built?
          end.
          tap do |nodes|
            render_permanent_pxelinux_configs(nodes)
            rerendered_nodes.push(*nodes)
          end.
          each do |node|
            Output.stderr "Node #{node.name} built."
          end

          all_nodes_reported_built = rerendered_nodes.length == @nodes.length
          break if all_nodes_reported_built

          sleep @config.build_poll_sleep
        end
      end

      def render_all_permanent_pxelinux_configs
        render_permanent_pxelinux_configs(@nodes)
      end

      def render_permanent_pxelinux_configs(nodes)
        nodes.template_each firstboot: false do |parameters, node|
          render_pxelinux(parameters, node)
        end
      end

      def teardown
        clear_up_built_node_marker_files
        Output.stderr 'Done.'
      end

      def clear_up_built_node_marker_files
        glob = File.join(@config.built_nodes_storage_path, '*')
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
        if agree(should_rerender)
          render_all_permanent_pxelinux_configs
        end
      end
    end
  end
end
