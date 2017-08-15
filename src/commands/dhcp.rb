# frozen_string_literal: true

#==============================================================================
# Copyright (C) 2017 Stephen F. Norledge and Alces Software Ltd.
#
# This file/package is part of Alces Metalware.
#
# Alces Metalware is free software: you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License
# as published by the Free Software Foundation, either version 3 of
# the License, or (at your option) any later version.
#
# Alces Metalware is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this package.  If not, see <http://www.gnu.org/licenses/>.
#
# For more information on the Alces Metalware, please visit:
# https://github.com/alces-software/metalware
#==============================================================================

require 'command_helpers/base_command'
require 'constants'
require 'output'
require 'templater'
require 'system_command'

module Metalware
  module Commands
    class Dhcp < CommandHelpers::BaseCommand
      DHCPD_HOSTS_FILE = '/etc/dhcp/dhcpd.hosts'
      RENDERED_DHCPD_HOSTS_STAGING_FILE = File.join(
        Constants::CACHE_PATH, 'last-rendered.dhcpd.hosts'
      )
      VALIDATE_DHCPD_CONFIG = "dhcpd -t -cf #{RENDERED_DHCPD_HOSTS_STAGING_FILE}"

      private

      def setup; end

      def run
        render_template
        validate_rendered_template!
        install_rendered_template
      end

      def dependency_hash
        {
          repo: ["dhcp/#{options.template}"],
        }
      end

      def render_template
        Templater.render_to_file(
          config, template_path, RENDERED_DHCPD_HOSTS_STAGING_FILE
        )
      end

      def template_path
        File.join(config.repo_path, 'dhcp', options.template)
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
