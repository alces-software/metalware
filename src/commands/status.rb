# frozen_string_literal: true

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
require 'command_helpers/base_command'
require 'command_helpers/node_identifier'
require 'status/monitor'
require 'status/job'
require 'fileutils'
require 'exceptions'

module Metalware
  module Commands
    class Status < CommandHelpers::BaseCommand
      private

      prepend CommandHelpers::NodeIdentifier

      def setup
        @opt = options
        if @opt.thread_limit < 1
          raise InvalidInput, 'The thread limit can not be less than 1'
        elsif @opt.wait_limit < 1
          raise InvalidInput, 'The wait limit can not be less than 1s'
        end
        @cmds = [:power, :ping]
      end

      def node_names
        @node_names ||= nodes.map(&:name)
      end

      def run
        start_monitor
        collect_data
        @monitor.thread.join
      end

      def start_monitor
        @monitor = Metalware::Status::Monitor.new(
          nodes: node_names,
          cmds: @cmds,
          thread_limit: @opt.thread_limit,
          wait_limit: @opt.wait_limit
        )
        @monitor.start
      end

      def collect_data
        data = {}
        empty_count = 0
        while data['FINISHED'] != true
          data = get_finished_data

          if data.empty?
            empty_count += 1
            if empty_count > 100 && @monitor.thread.stop?
              raise StatusDataIncomplete
            end
          elsif data['FINISHED'] != true
            display_data data
            empty_count = 0
          end

          sleep 1 if data.empty? # Only looks for updated data every second
        end
      end

      def display_data(data = {})
        print_header unless @header_been_printed

        format_str = '%-10s'
        printf format_str, data[:nodename]
        @cmds.each { |cmd| printf " | #{format_str}", data[cmd] }
        puts
      end

      def print_header
        @header_been_printed = true
        header_data = {}
        header_underline_hash = {}
        header_underline_string = '----------'
        header_data[:nodename] = 'Node'
        header_underline_hash[:nodename] = header_underline_string
        @cmds.each do |c|
          header_data[c] = c.to_s.capitalize
          header_underline_hash[c] = header_underline_string
        end
        display_data header_data
        display_data header_underline_hash
      end

      def get_finished_data
        @finished_node_index ||= 0
        return { 'FINISHED' => true } unless @finished_node_index < nodes.length
        nodename = node_names[@finished_node_index]

        current_results = Metalware::Status::Job.results.tap do |r|
          return {} if r.nil?
          return {} unless r.key? nodename
          r = r[nodename]
          @cmds.each { |cmd| return {} unless r.key? cmd }
          r[:nodename] = nodename
        end

        @finished_node_index += 1
        current_results[nodename]
      end
    end
  end
end
