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
require 'alces/stack/iterator'
require 'alces/stack/log'
require 'alces/stack/options'
require 'alces/stack/status/job'

module Alces
  module Stack
    module Status
      class Monitor
        def initialize(options = {})
          @status_log = Alces::Stack::Log.create_log('/var/log/metalware/status.log')
          @opt = Alces::Stack::Options.new(options)
          @queue = Queue.new
          @running = []
        end

        def start
          @thread = Thread.new {
            @status_log.info "Monitor Thread: #{Thread.current}"
            create_jobs
            monitor_jobs
          }
          self
        end

        attr_reader :thread

        # ----- THREAD METHODS BELOW THIS LINE ------
        def add_job_queue(nodename, cmd)
          @queue.push({ nodename: nodename, cmd: cmd })
        end

        def start_next_job(idx)
          job = @queue.pop
          @running[idx] = Alces::Stack::Status::Job
            .new(job[:nodename], job[:cmd], @opt.limit).start
        end

        def create_jobs
          idx = 0
          @opt.nodes.each do |node|
            @opt.cmds.each do |cmd|
              add_job_queue(node, cmd)
              if idx < @opt.limit
                start_next_job(idx)
                idx += 1
              end
            end 
          end
        end

        def monitor_jobs
          while @running.length > 0
            @running.each_with_index do |job, idx|
              unless job.thread.alive?
                job.thread.join
                if @queue.length > 0
                  start_next_job(idx)
                else
                  @running.delete_at(idx)
                end
              end
            end
            sleep 1
          end
        end
      end
    end
  end
end
