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
module Alces
  module Stack
    class ForkProcess
      def initialize(parent_lambda, child_lambda)
        @parent_lambda = parent_lambda
        @child_lambda = child_lambda
      end
      def run
        @pid = Process.fork
        if @pid
          @parent_lambda.call(self, @pid)
          Process.detach(@pid)
        else
          begin
            @child_lambda.call
          ensure
            Kernel.exit!
          end
        end
      end

      def wait_child_terminated(maxtime=0)
        start = Time.now
        while maxtime == 0 or maxtime > Time.now - start
          return true if @pid == Process.waitpid(@pid, Process::WNOHANG)
        end
        return false
      end

      def interrupt_child
        signal_child(2)
      end

      def kill_child
        signal_child(9)
      end

      def signal_child(sig)
        Process.kill(sig, @pid)
      end
      class << self
        def test
          parent_lambda = -> (fork, pid) {
            puts "Parent going to sleep"
            fork.wait_child_terminated(10)
            fork.interrupt_child
            fork.wait_child_terminated
            puts "Parent Finished"
          }
          child_lambda = lambda{
            begin
              puts "Child: Do you want to watch me count?"
              c = 0
              while true
                sleep 1
                c += 1
                puts c
              end
            rescue Interrupt
              puts "Child: Received interrupt"
            end
          }
          self.new(parent_lambda, child_lambda).run
        end
      end
    end
  end
end