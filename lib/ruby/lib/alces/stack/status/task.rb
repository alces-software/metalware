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
require 'timeout'
require 'alces/stack/log'

module Alces
  module Stack
    module Status
      class Task
        class << self
          def time
            Alces::Stack::Log.warn "Timeout not specified, using default" if @time.nil?
            @time ||= 10
          end

          attr_writer :time
          attr_accessor :log
          attr_accessor :report_file
        end

        include Alces::Tools::Execution

        def initialize(node, job)
          @node = node
          @job = job
        end

        def fork!
          @pid = fork do
            self.class.log.info "Task, #{Process.pid}, #{@node}, #{@job}"
            start
            Kernel.exit
          end
          return self
        rescue Interrupt
        rescue => e
          self.class.log.fatal e.inspect
          raise e
        end

        def wait; Process.waitpid(@pid); end
        def pid; @pid; end

        # ----- FORKED METHODS BELOW THIS LINE ------
        
        def write(msg)
          timer = 2 - (Time.now - @start_time)
          sleep timer if timer > 0
          msg = "#{msg.chomp("\n")}\n"
          File.open(self.class.report_file, "a") do |f|
            f.flock(File::LOCK_EX)
            f.write(msg)
          end
        rescue Interrupt
        end
        
        CLI_LIBRARY = {
          :power => :job_power_status,
          :ping => :job_ping_node
        }

        def start
          @start_time = Time.now
          Timeout::timeout(self.class.time) {
            @data = send(CLI_LIBRARY[@job], @node)
          }
        rescue Interrupt
        rescue Timeout::Error
          @data = "timeout"
        ensure
          teardown
        end

        def job_power_status(nodename)
          metal = "#{ENV['alces_BASE']}/bin/metal"
          cmd = "#{metal} power #{nodename} status 2>&1"
          result = run_bash(cmd)
                    .scan(/Chassis Power is .*\Z/)[0].to_s
                    .scan(Regexp.union(/on/, /off/))[0]
          result.nil? ? "error" : result
        end

        def job_ping_node(nodename)
          cmd = "ping -c 1 #{nodename} >/dev/null 2>&1; echo $?"
          result = run_bash(cmd)
          result.chomp == "0" ? "ok" : "error"
        end

        def run_bash(cmd)
          read_bash, write_bash = IO.pipe
          file = "/proc/#{Process.pid}/fd/#{write_bash.fileno}"
          @bash_pid = fork {
            read_bash.close
            Process.exec("#{cmd} | cat > #{file}")
          }
          Process.waitpid(@bash_pid)
          write_bash.close
          read_bash.read
        end

        def teardown
          data_hash = 
          tasks = [
            lambda { 
              h = {
                nodename: @node,
                cmd: @job,
                data: @data
              }
              write h.to_s
            },
            lambda {
              Process.kill(2, @bash_pid) unless @bash_pid.nil?
            }
          ]
          tasks.each do |t|
            begin
              t.call
            rescue => e
              self.class.log.error e.inspect unless e.is_a? Errno::ESRCH
            end
          end
        end
      end
    end
  end
end
