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
require 'alces/tools/cli'
require 'alces/stack/iterator'

module Alces
  module Stack
    module Status
      class Run
        include Alces::Tools::Execution

        def initialize(options={})
          @opt = Options.new(options)
        end

        class Options
          def initialize(options)
            @options = options
            assert_preconditions
          end

          def assert_preconditions
            raise InputError.new "Requires: -n xor -g" unless group? ^ nodename?
          end
          class InputError < StandardError; end

          def method_missing(s, *a, &b)
            if @options.key?(s)
              @options[s]
            elsif s[-1] == "?"
              !!@options[s[0...-1].to_sym]
            else
              super
            end
          end
        end

        def run!
          set_pipes
          teacher = fork_processes
          unless monitor_children(teacher)
            kill_children
            Process.waitpid(teacher)
          end
          display_results
        end

        def set_pipes
          @read_data, @write_data = IO.pipe
          @read_pids, @write_pids = IO.pipe
        end

        def fork_processes
          fork do
            pids = fork_cmd(:power)
            pids.concat fork_cmd(:ping)
            @write_pids.puts pids
            @write_pids.close
            @write_data.close
            Process.waitall
          end
        end

        def monitor_children(teacher)
          start_time = Time.now
          result = nil
          while Time.now - start_time < @opt.wait && result.nil?
            result = Process.waitpid(teacher, Process::WNOHANG)
          end
          !!result
        end

        def kill_children
          puts "Process timed out before all nodes responded. Check log for details"
          Alces::Stack::Log.warn "Process timed. Node may return before receiving SIGINT"
          @write_pids.close
          @read_pids.read.split("\n").each do |pid|
            begin Process.kill(2, pid.to_i); rescue Errno::ESRCH; end
          end
        end

        def fork_cmd(cmd)
          lambda_proc = lambda do |options|
            Process.fork do
              begin
                @write_pids.close
                nodename = options[:nodename]
                result = send(cmd, nodename)
                @write_data.puts "#{cmd} : #{nodename} : #{result}"
              rescue Interrupt
                Alces::Stack::Log.error "Could not determine '#{cmd}' for node '#{nodename}'"
              ensure
                @write_data.close
              end
            end
          end
          Alces::Stack::Iterator.run(@opt.group, lambda_proc, nodename: @opt.nodename)
        end

        def power(nodename)
          result = `#{ENV['alces_BASE']}/bin/metal power #{nodename} status 2>&1`
                     .scan(/Chassis Power is .*\Z/)[0].to_s
                     .scan(Regexp.union(/on/, /off/))[0]
          result.nil? ? "error" : result
        end

        def ping(nodename)
          result = `ping -c 1 #{nodename} > /dev/null; echo $?`
          result.chomp == "0" ? "ok" : "error"
        end

        def display_results
          @write_data.close
          puts @read_data.read
        end
      end
    end
  end
end
