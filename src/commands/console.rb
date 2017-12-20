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

require 'pty'
require 'commands/ipmi'

module Metalware
  module Commands
    class Console < Ipmi
      private

      def run
        puts "Attempting to connect to node #{node_names[0]}.."
        if valid_connection?
          puts 'Establishing SOL connection, type &. to exit..'
          ipmi(command('activate'))
        else
          puts 'Failed to connect..'
        end
      end

      def command(type)
        "ipmitool -H #{render_hostname} #{render_credentials} -e '&' -I lanplus sol #{type}"
      end

      def valid_connection?
        ipmi(command('info'))
      end
    end
  end
end
