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
require 'alces/stack/status/task'

module Alces
  module Stack
    module Status
      class Jobs
        include Alces::Tools::Execution

        def initialize()
          @running = {}
          reset_queue
        end

        attr_reader :running

        def reset_queue
          @queue = {
            head: false,
            tail: false
          }
        end

        def generate_key
          key = :head
          while @queue.key? key do 
            key = ("_" + rand(36**8).to_s(36)).to_sym
          end
          return key
        end

        def add(node, cmd)
          key = generate_key
          @queue[key] = {
            node: node,
            cmd: cmd,
            next: false
          }
          @queue[:head] = key unless @queue[:head]
          old_tail = @queue[:tail]
          @queue[old_tail][:next] = key if old_tail
          @queue[:tail] = key
        end

        def remove_head
          msg = "Can not remove job, queue is empty"
          raise EmptyJobQueue.new msg unless @queue[:head]

          old_head = @queue[:head]
          new_head = @queue[old_head][:next]
          @queue.delete(old_head)
          @queue[:head] = new_head
          @queue[:tail] = false unless @queue[:head]
        rescue EmptyJobQueue => e
          Alces::Stack::Log.error e.inspect
        end

        def start
          msg = "Can not start job, queue is empty"
          raise EmptyJobQueue.new msg unless @queue[:head]

          next_job = @queue[@queue[:head]]
          task = Alces::Stack::Status::Task
                   .new(next_job[:node], next_job[:cmd])
          @running[task.fork!.pid] = {
            node: next_job[:node],
            cmd: next_job[:cmd],
            task: task
          }
          remove_head
        rescue EmptyJobQueue => e
          Alces::Stack::Log.error e.inspect
        end

        def start?
          !!@queue[:head]
        end

        class EmptyJobQueue < StandardError; end

        def finished
          pid = Process.waitpid
          @running.delete(pid)
          return true
        rescue Errno::ECHILD
          return false
        end

        def print_queue
          cur = @queue[:head]
          while cur
            puts "#{@queue[cur][:node]} #{@queue[cur][:cmd]}"
            cur = @queue[cur][:next]
          end
        end

        def print_queue_hash
          puts @queue
        end
      end
    end
  end
end
