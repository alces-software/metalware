
require 'config'
require 'templater'
require 'constants'
require 'node'
require 'nodes'
require 'iterator'
require 'output'

# XXX Need to handle interrupts

module Metalware
  module Commands
    class Build
      def initialize(args, options)
        setup(args, options)
        render_build_templates
        wait_for_nodes_to_build
        render_permanent_pxelinux_configs
        teardown
      rescue Interrupt
        Output.stderr 'Exiting...'
        teardown
      end

      private

      def setup(args, options)
        options.default \
          kickstart: 'default',
          pxelinux: 'default'
        @options = options
        @config = Config.new(options.config)
        node_identifier = args.first
        @nodes = Nodes.new(@config, node_identifier, options.group)
      end

      def render_build_templates
        @nodes.template_each firstboot: true do |templater, node|
          render_kickstart(templater, node)
          render_pxelinux(templater, node)
        end
      end

      def render_kickstart(templater, node)
        kickstart_template_path = template_path :kickstart
        # XXX Ensure this path has been created
        kickstart_save_path = File.join(
          @config.rendered_files_path, 'kickstart', node.name
        )
        templater.save(kickstart_template_path, kickstart_save_path)
      end

      def render_pxelinux(templater, node)
        # XXX handle nodes without hexadecimal IP, i.e. nodes not in `hosts`
        # file yet - best place to do this may be when creating `Node` objects?
        pxelinux_template_path = template_path :pxelinux
        pxelinux_save_path = File.join(
          @config.pxelinux_cfg_path, node.hexadecimal_ip
        )
        templater.save(pxelinux_template_path, pxelinux_save_path)
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
        while !all_nodes_built?
          sleep @config.build_poll_sleep
        end
      end

      def all_nodes_built?
        @nodes.all? { |node| node.built? }
      end

      def render_permanent_pxelinux_configs
        @nodes.template_each firstboot: false do |templater, node|
          if node.built?
            render_pxelinux(templater, node)
          end
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
    end
  end
end
