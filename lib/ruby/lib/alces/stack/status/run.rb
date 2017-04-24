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
    class Options
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
          @opt = Alces::Stack::Options.new(options)
        end

        def run!
          start_monitor
          display_data
          @monitor.thread.join
        end
        
        def start_monitor
          @monitor = Alces::Stack::Status::Monitor.new({
              nodes: @opt.nodes,
              cmds: @opt.cmds,
              thread_limit: @opt.thread_limit
            })
          @monitor.start
        end

        def display_data
          while !(data = get_finished_data).class.is_a? (Finished)
            raise "Monitor thread has died" if @monitor.thread.stop? && !data
            puts data if data
          end
        end

        def get_finished_data
          @finished_node_index ||= 0
          return Finished.new unless @finished_node_index < @opt.nodes.length

          nodename = @opt.nodes[@finished_node_index]
          current_results = nil
          Alces::Stack::Status::Job.results.tap do |r|
            return false if r.nil?
            current_results = r[nodename]
            return false if current_results.nil?
          end
          
          @opt.cmds.each { |cmd| return false unless current_results.key? cmd }
          @finished_node_index += 1
          current_results
        end
        class Finished; end
      end
    end
  end
end
