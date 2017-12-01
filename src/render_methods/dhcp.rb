# frozen_string_literal: true

require 'file_path'
require 'system_command'

module Metalware
  module RenderMethods
    class DHCP < RenderMethod
      RESTART_DHCP = 'systemctl restart dhcpd'
      VALIDATE_DHCPD_CONFIG = 'dhcpd -t -cf'

      class << self
        def restart_service
          SystemCommand.run RESTART_DHCP
        end

        def validate(content)
          run_in_temp_file(content) do |file|
            cmd = "#{VALIDATE_DHCPD_CONFIG} #{file.path}"
            SystemCommand.run cmd
          end
        end

        def managed?
          false
        end

        private

        def staging_opts
          {
            managed: managed?,
            validator: name,
            service: name,
          }
        end

        def sync_location
          FilePath.dhcpd_hosts
        end

        def template(namespace)
          FilePath.template_path('dhcp', node: namespace)
        end
      end
    end
  end
end
