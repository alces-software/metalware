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
        if vm?
          libvirt = Metalware::Vm.new(libvirt_info[:host], node_names[0])
        elsif valid_connection?
          puts 'Establishing SOL connection, type &. to exit ..'
          system(command('activate'))
        else
          raise MetalwareError, "Unable to connect to #{node_names[0]}"
        end
      end

      def command(type)
        "ipmitool -H #{node.name} #{render_credentials} -e '&' -I lanplus sol #{type}"
      end

      def valid_connection?
        SystemCommand.run(command('info'))
      end
    end
  end
end