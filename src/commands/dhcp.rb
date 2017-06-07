
require 'base_command'
require 'constants'
require 'output'
require 'templater'
require 'system_command'


module Metalware
  module Commands
    class Dhcp < BaseCommand
      DHCPD_HOSTS_FILE = '/etc/dhcp/dhcpd.hosts'
      RENDERED_DHCPD_HOSTS_STAGING_FILE = File.join(
        Constants::CACHE_PATH, 'last-rendered.dhcpd.hosts'
      )
      VALIDATE_DHCPD_CONFIG = "dhcpd -t -cf #{RENDERED_DHCPD_HOSTS_STAGING_FILE}"

      private

      def setup(args, options)
        @options = options
      end

      def run
        render_template
        validate_rendered_template!
        install_rendered_template
      end

      def render_template
        Templater.render_to_file(
          config, template_path, RENDERED_DHCPD_HOSTS_STAGING_FILE
        )
      end

      def template_path
        File.join(config.repo_path, 'dhcp', @options.template)
      end

      def validate_rendered_template!
        _stdout, stderr, status = Open3.capture3(VALIDATE_DHCPD_CONFIG)
        if status.exitstatus != 0
          Output.stderr "Validating rendered 'dhcpd.hosts' failed:"
          Output.stderr_indented_error_message stderr
          Output.stderr "Rendered template can be inspected at '#{RENDERED_DHCPD_HOSTS_STAGING_FILE}'"
          exit 1
        end
      end

      def install_rendered_template
        FileUtils.copy(RENDERED_DHCPD_HOSTS_STAGING_FILE, DHCPD_HOSTS_FILE)
        SystemCommand.run 'systemctl restart dhcpd'
      end
    end
  end
end
