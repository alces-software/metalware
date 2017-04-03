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
require 'alces/stack/status/jobs'

module Alces
  module Stack
    module Status
      class Monitor
        class << self
          attr_accessor :log
        end
        include Alces::Tools::Execution

        def initialize(nodes, cmds, limit)
          @limit = limit
          @nodes = nodes
          @cmds = cmds
        end

        def fork!
          @pid = fork do
            self.class.log.info "Monitor #{Process.pid}"
            start
          end
          return self
        end

        def wait; Process.waitpid(@pid); end
        def wait_wnohang; Process.waitpid(@pid, Process::WNOHANG); end

        def pid; @pid; end

        def kill
          puts "KILL"
          if @kill_sig_received
            Process.kill(9, @pid) unless @pid.nil?
            Alces::Stack::Log.warn "Force shutdown of monitor process"
          end
        rescue
        end

        # ----- FORKED METHODS BELOW THIS LINE ------
        def start
          create_jobs
          monitor_jobs
        rescue StandardError => e
          Alces::Stack::Log.fatal e.inspect
          self.class.log.fatal e.inspect
          @error = true
          teardown_jobs
          raise e
        rescue Interrupt
          @error = true
        ensure
          teardown_jobs
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

        def teardown_jobs
          $stdout.flush
          $stderr.flush
          $stderr.print "Exiting...." if @error
          @jobs.reset_queue
          running = @jobs.running
          unless running.nil?
            running.keys.each { |k| 
              begin; Process.kill(2, k); rescue; end
            }
          end 
          monitor_jobs
          $stderr.puts "Done" if @error
          Kernel.exit
        rescue Interrupt
          running = @jobs.running
          unless running.nil?
            running.keys.each { |k| 
              begin; Process.kill(2, k); rescue; end
            }
          end
          $stderr.puts "FORCED EXIT"
        end
      end
    end
  end
end
