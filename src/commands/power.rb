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
    class Power < Ipmi
      private

      def run
        ipmi(command)
      end

      def command
        if @options.group
          hosts = "-g #{node_names[0]}"
        else
          hosts = "-H #{node_names[0]}"
        end
        "ipmitool #{hosts} #{render_credentials} #{render_command(@args[1].to_s)}"
      end

      def render_command(cmd)
        case cmd
        when 'on'
          'chassis power on'
        when 'off'
          'chassis power off'
        when 'locate'
          'chassis identify force'
        when 'locateoff'
          'chassis identify 0'
        when 'status'
          'chassis power status'
        when 'cycle'
          'chassis power cycle'
        when 'reset'
          'chassis power reset'
        when 'sensor'
          'sensor'
        else
          raise 'Invalid power command'
        end
      end
    end
  end
end
