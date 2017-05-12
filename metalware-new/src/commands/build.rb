
require 'templater'
require 'constants'
require 'node'

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

        render_kickstart
        render_pxelinux
      end

      private

      def node
        @node ||= Node.new(args.first)
      end

      def templater
        @templater ||= Templater::Combiner.new({nodename: node.name})
      end

      def render_kickstart
        kickstart_template_path = template_path :kickstart
        # XXX Ensure this path has been created
        kickstart_save_path = File.join(
          Constants::RENDERED_PATH, 'kickstart', node.name
        )
        templater.save(kickstart_template_path, kickstart_save_path)
      end

      def render_pxelinux
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
