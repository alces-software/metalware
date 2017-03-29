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
              Kernel.exit
            else
              @int_once = true
            end
          }
        end

        def set_logging
          status_log = Alces::Stack::Log.create_log("/var/log/metalware/status.log")
          status_log.progname = "status"
          Alces::Stack::Status::Monitor.log = status_log
          Alces::Stack::Status::Task.log = status_log
        end

        def node_list
          lambda_proc = lambda { |options| options[:nodename] }
          nodes = Alces::Stack::Iterator.run(@opt.group, lambda_proc, nodename: @opt.nodename)
          nodes = [nodes] unless nodes.is_a? Array
          nodes
        end

        def setup_reporting
          Alces::Stack::Status::Task.time = 10
          @report_file = "/tmp/metalware-status.#{Process.pid}"
          FileUtils.touch(@report_file)
          File.delete(@report_file) if File.exist?(@report_file)
          Alces::Stack::Status::Task.report_file = @report_file
        end

        def run!
          set_logging
          setup_reporting
          nodes = node_list
          cmds = [:power, :ping]
          monitor = Alces::Stack::Status::Monitor.new(nodes, cmds, 50).fork!
          set_signal
          while monitor.wait_wnohang.nil?
            File.open(@report_file, "a+") do |f|
              f.flock(File::LOCK_EX)
              data = f.read
              puts data
              f.truncate(0)
            end
            sleep 1
          end
        ensure
          File.delete(@report_file) if File.exist?(@report_file.to_s)
        end
      end
    end
  end
end
