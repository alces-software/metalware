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
        include Alces::Tools::Execution

        def initialize(nodes, cmds, limit)
          @limit = limit
          @nodes = nodes
          @cmds = cmds
        end

        def fork!
          @read, @write = IO.pipe
          @pid = fork do
            @read.close
            start
          end
          @write.close
          return self
        end

        def wait
          Process.waitpid(@pid)
        end

        def read
          @read.read
        end

        def pid; @pid; end

        # ----- FORKED METHODS BELOW THIS LINE ------
        
        def write(msg)
          @write.puts msg
        end

        def start
          create_jobs
          monitor_jobs
        rescue Interrupt
          print "Exiting...."
          @jobs.reset_queue
          #@jobs.interrupt
          monitor_jobs
          puts "Done"
        rescue StandardError => e
          Alces::Stack::Log.fatal e.inspect
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
          while result = @jobs.finished
            @jobs.start if @jobs.start?
          end
        end
      end
    end
  end
end
