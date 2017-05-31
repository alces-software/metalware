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
require 'alces/tools/cli'
require 'alces/stack'
require 'alces/stack/templater'
require 'alces/stack/log'

module Alces
  module Stack
    module Status
      class CLI
        include Alces::Tools::CLI

        root_only
        name 'metal status'
        description ""
        log_to File.join(Alces::Stack.config.log_root,'alces-node-hosts.log')

        option  :nodename,
                'Node name to be modified',
                '-n', '--node-name',
                default: false

        option  :group,
                'Specify a gender group to run over',
                '-g', '--node-group',
                default: false

        option  :time_limit,
                'How long to wait in seconds. Minimum 5s',
                '-w', '--wait',
                default: "5"

        option  :thread_limit,
                'Limit on number of tasks to run in parallel',
                '-t', '--thread-limit',
                default: 10

        def assert_preconditions!
          msg = "metal status #{ARGV.to_s.gsub(/[\[\],\"]/, "")}"
          Alces::Stack::Log.progname = "status"
          Alces::Stack::Log.info msg
          self.class.assert_preconditions!
        end

        def execute
          Alces::Stack::Status.run!(
              nodename: nodename,
              group: group,
              thread_limit: thread_limit,
              time_limit: time_limit.to_i < 5 ? 5 : time_limit.to_i
            )
        rescue => e
          Alces::Stack::Log.fatal e.inspect
          raise e
        end
      end
    end
  end
end