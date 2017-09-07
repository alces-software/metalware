
# frozen_string_literal: true

require 'build_methods'

module Metalware
  module BuildMethods
    module Kickstarts
      class Pxelinux < Kickstart
        REPO_DIR = :pxelinux

        private

        def save_path
          # XXX handle nodes without hexadecimal IP, i.e. nodes not in `hosts`
          # file yet - best place to do this may be when creating `Node` objects?
          File.join(config.pxelinux_cfg_path, node.hexadecimal_ip)
        end
      end
    end
  end
end