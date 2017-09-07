
# frozen_string_literal: true

require 'build_methods/kickstart_base'

module Metalware
  module BuildMethods
    class Kickstart < KickstartBase
      TEMPLATES = [:kickstart, :pxelinux].freeze

      private

      def pxelinux_repo_dir
        :pxelinux
      end

      def save_path
        # XXX handle nodes without hexadecimal IP, i.e. nodes not in `hosts`
        # file yet - best place to do this may be when creating `Node` objects?
        File.join(config.pxelinux_cfg_path, node.hexadecimal_ip)
      end
    end
  end
end
