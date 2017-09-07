
# frozen_string_literal: true

module Metalware
  module BuildMethods
    class KickstartBase < BuildMethod
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
        render_template(pxelinux_repo_dir,
                        parameters: parameters,
                        save_path: save_path)
      end

      def pxelinux_repo_dir
        raise NotImplementedError
      end

      def save_path
        raise NotImplementedError
      end
    end
  end
end
