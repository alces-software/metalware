
# frozen_string_literal: true

require 'build_methods'

module Metalware
  module BuildMethods
    module Kickstarts
      class Pxelinux < Kickstart
        private

        def pxelinux_template_path
          file_path.template_path(:pxelinux, node: node)
        end

        def save_path
          # XXX handle nodes without hexadecimal IP, i.e. nodes not in `hosts`
          # file yet - best place to do this may be when creating
          # `Node` objects?
          File.join(FilePath.pxelinux_cfg, node.hexadecimal_ip)
        end
      end
    end
  end
end
