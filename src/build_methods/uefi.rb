
# frozen_string_literal: true

module Metalware
  module BuildMethods
    class UEFI < Kickstart
      private

      def pxelinux_repo_dir
        :'pxelinux/uefi'
      end
    end
  end
end
