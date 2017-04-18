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
require 'alces/tools/execution'
require 'alces/stack/iterator'
require 'alces/stack/log'
require 'alces/stack/options'
require 'alces/stack/status/job'

module Alces
  module Stack
    module Status
      class Monitor
        include Alces::Tools::Execution

        def initialize(options = {})
          @status_log = Alces::Stack::Log.create_log('/var/log/metalware/status.log')
          @opt = Alces::Stack::Options.new(options)
          @queue = Queue.new
        end

        def start
          @thread = Thread.new {
            @status_log.info "Monitor Thread: #{Thread.current}"

          }
          self
        end

        attr_reader :thread

        # ----- THREAD METHODS BELOW THIS LINE ------
        def add_job_queue(nodename, cmd)
          @queue.push({ nodename: nodename, cmd: cmd })
        end

        def start_next_job(nodename, cmd)
          job = @queue.pop
          
        end

        def create_jobs
          @jobs = Alces::Stack::Status::Jobs.new()
          @nodes.each do |node|
            @cmds.each do |cmd|
              @jobs.add(node, cmd)
              if @limit > 0
                @jobs.start
                @limit -= 1
              end
            end 
          end
        end

        def monitor_jobs
          while @jobs.finished
            @jobs.start if @jobs.start?
          end
        end
      end
    end
  end
end
