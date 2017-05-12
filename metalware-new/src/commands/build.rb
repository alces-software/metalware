
require 'templater'
require 'constants'
require 'node'
require 'iterator'

module Metalware
  module Commands
    class Build
      attr_reader :args, :options

      def initialize(args, options)
        options.default \
          kickstart: 'default',
          pxelinux: 'default'
        @args = args
        @options = options

        node_identifier = args.first
        maybe_node = options.group ? nil : node_identifier
        maybe_group = options.group ? node_identifier : nil

        lambda_proc = -> (template_parameters) do
          node = Node.new(template_parameters[:nodename])
          templater = Templater::Combiner.new(template_parameters)
          render_kickstart(templater, node)
          render_pxelinux(templater, node)
        end

        template_parameters = {
          nodename: maybe_node
        }

        Iterator.run(maybe_group, lambda_proc, template_parameters)

        built_nodes = []
        nodes_built_lambda_proc = -> (iterator_options) do
          built_nodes << Node.new(iterator_options[:nodename]).built?
        end

        all_nodes_built = false
        iterator_options = {nodename: maybe_node}
        while !all_nodes_built
          built_nodes = []
          Iterator.run(maybe_group, nodes_built_lambda_proc, iterator_options).all?
          all_nodes_built = built_nodes.all?

          sleep Constants::BUILD_POLL_SLEEP
        end
      end

      private

      def render_kickstart(templater, node)
        kickstart_template_path = template_path :kickstart
        # XXX Ensure this path has been created
        kickstart_save_path = File.join(
          Constants::RENDERED_PATH, 'kickstart', node.name
        )
        templater.save(kickstart_template_path, kickstart_save_path)
      end

      def render_pxelinux(templater, node)
        # XXX handle nodes without hexadecimal IP, i.e. nodes not in `hosts`
        # file yet - best place to do this may be when creating `Node` objects?
        pxelinux_template_path = template_path :pxelinux
        pxelinux_save_path = File.join(
          '/var/lib/tftpboot/pxelinux.cfg', node.hexadecimal_ip
        )
        templater.save(pxelinux_template_path, pxelinux_save_path)
      end

      def template_path(template_type)
        File.join(
          Constants::REPO_PATH,
          template_type.to_s,
          options.__send__(template_type)
        )
      end
    end
  end
end
