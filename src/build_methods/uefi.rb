
# frozen_string_literal: true

require 'build_methods/kickstart_base'

module Metalware
  module BuildMethods
    class UEFI < KickstartBase
      TEMPLATES = [:kickstart, :uefi].freeze

      private

      def pxelinux_repo_dir
        :uefi
      end

      def save_path
        File.join(file_path.uefi_save, "grub.cfg-#{node.hexadecimal_ip}")
      end
    end
  end
end
