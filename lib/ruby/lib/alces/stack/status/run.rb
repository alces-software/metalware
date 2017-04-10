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
            raise InputError.new "Requires: -n xor -g" if group? == nodename?
          end
          class InputError < StandardError; end

          def nodes
            @nodes ||= _set_nodes
          end

          def _set_nodes
            lambda_proc = lambda { |options| options[:nodename] }
            a = Alces::Stack::Iterator.run(group, lambda_proc, nodename: nodename)
            a = [a] unless a.is_a? Array 
            a
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

        def run!
          @monitor = Alces::Stack::Status::Monitor.new(@opt.nodes,
                                                       @opt.cmds,
                                                       50,
                                                       @opt.status_log)
          @monitor.start
          sleep 1
        end
        
      end
    end
  end
end
