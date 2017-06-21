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

module Metalware
  module DeploymentServer
    class << self

      def ip
        SystemCommand.run(determine_hostip_script).chomp
      rescue SystemCommandError
        # If script failed for any reason fall back to using `hostname -i`,
        # which may or may not give the IP on the interface we actually want to
        # use (note: the dance with pipes is so we only get the last word in
        # the output, as I've had the IPv6 IP included first before, which
        # breaks all the things).
        # XXX Warn about falling back to this?
        SystemCommand.run(
          "hostname -i | xargs -d' ' -n1 | tail -n 2 | head -n 1"
        ).chomp
      end

      def system_file_url(system_file)
        url "system/#{system_file}"
      end

      def kickstart_url(node_name)
        if node_name
          path = File.join('kickstart', node_name)
          url path
        end
      end

      def build_complete_url(node_name)
        if node_name
          url "exec/kscomplete.php?name=#{node_name}"
        end
      end

      def build_file_url(node_name, namespace, file_name)
        path = File.join(node_name , namespace.to_s , file_name)
        url path
      end

      private

      def url(url_path)
        full_path = File.join('metalware', url_path)
        URI.join("http://#{ip}", full_path).to_s
      end

      def determine_hostip_script
        File.join(
          Constants::METALWARE_INSTALL_PATH,
          'libexec/determine-hostip'
        )
      end

    end
  end
end
