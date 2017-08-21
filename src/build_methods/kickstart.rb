
# frozen_string_literal: true

module Metalware
  module BuildMethods
    class Kickstart < BuildMethod
      TEMPLATES = [:kickstart, :pxelinux].freeze

      def render_build_started_templates(parameters)
        render_kickstart(parameters)
        render_pxelinux(parameters)
      end

      def render_build_complete_templates(parameters)
        render_pxelinux(parameters)
      end

      private

      def render_kickstart(parameters)
        render_template(:kickstart, parameters: parameters)
      end

      def render_pxelinux(parameters)
        # XXX handle nodes without hexadecimal IP, i.e. nodes not in `hosts`
        # file yet - best place to do this may be when creating `Node` objects?
        save_path = File.join(config.pxelinux_cfg_path, node.hexadecimal_ip)
        render_template(:pxelinux, parameters: parameters, save_path: save_path)
      end
    end
  end
end
