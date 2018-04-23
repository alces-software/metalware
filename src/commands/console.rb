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

require 'commands/ipmi'

module Metalware
  module Commands
    class Console < Ipmi
      private

      # Empty `setup` as we want to skip behaviour of `ipmi`'s `setup` method,
      # which is not relevant for the custom behaviour of `console` (ideally we
      # wouldn't inherit from it at all, but that's what we do for now).
      def setup; end

      def run
        if vm?(node)
          raise MetalwareError, 'Console not supported on virtual machines'
        end
        unless valid_connection?
          raise MetalwareError, "Unable to connect to #{node.name}"
        end
        puts 'Establishing SOL connection, type &. to exit..'
        system(console_command('activate'))
      end

      def valid_connection?
        SystemCommand.run(console_command('info'))
      end

      def console_command(type)
        ipmi_command(node, arguments: "-e '&' sol #{type}")
      end
    end
  end
end
