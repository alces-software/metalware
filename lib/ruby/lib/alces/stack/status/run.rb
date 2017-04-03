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
require 'alces/stack/status/monitor'
require 'alces/stack/status/task'
require 'alces/stack/iterator'
require 'alces/stack/log'
require 'fileutils'

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

          def nodes
            lambda_proc = lambda { |options| options[:nodename] }
            @nodes ||= lambda {
                a = Alces::Stack::Iterator
                      .run(group, lambda_proc, nodename: nodename)
                a = [a] unless a.is_a? Array 
                a
              }.call
          end

          def cmds
            [:power, :ping]
          end

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

        def set_signal
          Signal.trap("INT") {
            if @int_once
              @monitor.kill
            else
              @int_once = true
              begin
                @monitor.wait
              rescue
              end
            end
            File.delete(@report_file) if File.exist?(@report_file.to_s)
            Kernel.exit
          }
        end

        def set_logging
          status_log = Alces::Stack::Log.create_log("/var/log/metalware/status.log")
          status_log.progname = "status"
          Alces::Stack::Status::Monitor.log = status_log
          Alces::Stack::Status::Task.log = status_log
        end

        def set_reporting
          Alces::Stack::Status::Task.time = (@opt.wait < 5 ? 5 : @opt.wait)
          @report_file = "/tmp/metalware-status.#{Process.pid}"
          FileUtils.touch(@report_file)
          File.delete(@report_file) if File.exist?(@report_file)
          Alces::Stack::Status::Task.report_file = @report_file
          @results = {}
        end

        def run!
          set_logging
          set_reporting
          @monitor = Alces::Stack::Status::Monitor.new(@opt.nodes, @opt.cmds, 50).fork!
          set_signal
          next_loop, wait = true, true
          while next_loop
            File.open(@report_file, "a+") do |f|
              f.flock(File::LOCK_EX)
              process_data(f.read)
              f.truncate(0)
            end
            check_findished_node
            next_loop = false unless wait
            wait = @monitor.wait_wnohang.nil? if wait
            sleep 1 if next_loop
          end
        ensure
          File.delete(@report_file) if File.exist?(@report_file.to_s)
        end

        def process_data(data)
          data.split("\n").each do |entry|
            h = eval(entry.gsub(/\\n/, "\n"))
            (@results[h[:nodename].to_sym] ||= {})[h[:cmd]] = h[:data]
          end
        end

        def check_findished_node
          return if (@cur_index ||= 0) >= @opt.nodes.length
          h = (@results[@opt.nodes[@cur_index].to_sym] ||= {})
          complete = true
          @opt.cmds.each { |c| complete = false unless h.key? c }
          return unless complete
          display_result(h)
          @results.delete @opt.nodes[@cur_index].to_sym
          @cur_index += 1
          check_findished_node
        end

        def display_result(h = {})
          str = "#{@opt.nodes[@cur_index]} : "
          @opt.cmds.each { |c| str << "#{c} #{h[c]}, " }
          puts str
          $stdout.flush
        end
      end
    end
  end
end
