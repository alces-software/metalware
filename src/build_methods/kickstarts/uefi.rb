
# frozen_string_literal: true

require 'build_methods'

module Metalware
  module BuildMethods
    module Kickstarts
      class UEFI < Kickstart
        private

        def pxelinux_template_path
          file_path.repo_template_path(:'uefi-kickstart', namespace: node)
        end

        def save_path
          File.join(file_path.uefi_save, "grub.cfg-#{node_hexadecimal_ip}")
        end
      end
    end
  end
end
