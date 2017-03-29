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
          @read, @write = IO.pipe
          @read.sync = true
          @pid = fork do
            self.class.log.info "Monitor #{Process.pid}"
            @read.close
            start
          end
          @write.close
          return self
        end

        def wait; Process.waitpid(@pid); end
        def wait_wnohang; Process.waitpid(@pid, Process::WNOHANG); end
        def read; @read.read; end

        def pid; @pid; end

        def kill
          puts "KILL"
          if @kill_sig_received
            Process.kill(9, @pid) unless @pid.nil?
            Alces::Stack::Log.warn "Force shutdown of monitor process"
          else
            Process.kill(9, @pid) unless @pid.nil?
            @kill_sig_received = true
            Alces::Stack::Log.infor "Interrupt received, starting monitor teardown"
          end
        rescue
        end

        # ----- FORKED METHODS BELOW THIS LINE ------
        
        def write(msg)
          @write.puts msg
        end

        def start
          create_jobs
          Signal.trap("INT") { teardown_jobs }
          monitor_jobs
        rescue StandardError => e
          Alces::Stack::Log.fatal e.inspect
          self.class.log.fatal e.inspect
          teardown_jobs
          raise e
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
          $stderr.print "Exiting...."
          @jobs.reset_queue
          @running.keys.each { |k| 
            begin; Process.kill(2, k); rescue => e; end
          } unless @running.nil?
          monitor_jobs
          $stderr.puts "Done"
          Kernel.exit
        end
      end
    end
  end
end
