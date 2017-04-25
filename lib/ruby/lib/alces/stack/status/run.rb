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
require 'alces/tools/cli'
require 'alces/stack/iterator'
require 'alces/stack/log'
require 'alces/stack/options'
require 'alces/stack/status/monitor'
require 'alces/stack/status/job'
require 'fileutils'

module Alces
  module Stack
    class RunOptions < Alces::Stack::Options 
      def cmds
        [:power, :ping]
      end

      def nodes
        @nodes ||= _set_nodes
      end

      def _set_nodes
        lambda_proc = lambda { |lambda_hash| lambda_hash[:nodename] }
        a = Alces::Stack::Iterator.run(group, lambda_proc, nodename: nodename)
        a.is_a?(Array) ? a : [a]
      end
    end

    module Status
      class Run
        def initialize(options={})
          @opt = RunOptions.new(options)
        end

        def run!
          start_monitor
          collect_data
          @monitor.thread.join
        end
        
        def start_monitor
          @monitor = Alces::Stack::Status::Monitor.new({
              nodes: @opt.nodes,
              cmds: @opt.cmds,
              thread_limit: @opt.thread_limit,
              time_limit: @opt.time_limit
            })
          @monitor.start
        end

        def collect_data
          data = {}
          empty_count = 0
          while data["FINISHED"] != true
            data = get_finished_data
            if data.empty?
              empty_count += 1
              raise DataIncomplete if empty_count > 100 && @monitor.thread.stop?
            elsif data["FINISHED"] != true
              display_data data
              empty_count = 0
            end
            sleep 0.1
          end
        end

        class DataIncomplete < StandardError
          def initialize(msg = "Failed to receive data for all nodes")
            super
          end
        end

        def display_data(data = {})
          print_header unless @header_been_printed
          
          format_str = "%-10s"
          printf format_str, data[:nodename]
          @opt.cmds.each { |cmd| printf " | #{format_str}", data[cmd] }
          puts
        end

        def print_header
          @header_been_printed = true
          header_data = {}
          underline_h = {}
          underline_s = "----------"
          header_data[:nodename] = "Node"
          underline_h[:nodename] = underline_s
          @opt.cmds.each do |c|
            header_data[c] = c.to_s.capitalize
            underline_h[c] = underline_s
          end
          display_data header_data
          display_data underline_h
        end

        def get_finished_data
          @finished_node_index ||= 0
          return {"FINISHED" => true} unless @finished_node_index < @opt.nodes.length
          nodename = @opt.nodes[@finished_node_index]

          current_results = Alces::Stack::Status::Job.results.tap do |r|
            return {} if r.nil?
            return {} unless r.key? nodename
            r = r[nodename]
            @opt.cmds.each { |cmd| return {} unless r.key? cmd }
            r[:nodename] = nodename
          end
          
          @finished_node_index += 1
          current_results[nodename]
        end
      end
    end
  end
end
