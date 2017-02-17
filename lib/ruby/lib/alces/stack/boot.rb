
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
require 'alces/stack/boot/cli'
require 'alces/stack/boot/run'

module Alces
  module Stack
    module Boot
      class << self
        path = "hello"
        def run!(*args)
          Run.new(*args).run!
        end

        def create_file(template, ip)
          File.open('/tmp/metalware.boot', 'a').puts(ip)
          "cp #{template} /var/lib/tftpboot/pxelinux.cfg/#{ip}"
        end

        def delete_files
          if File.exist?('/tmp/metalware.boot')
            File.open('/tmp/metalware.boot', 'r').each do |line|
              `rm -f /var/lib/tftpboot/pxelinux.cfg/#{line}`
            end
          end
          `rm -f /tmp/metalware.boot`
        end
      end
    end
  end
end