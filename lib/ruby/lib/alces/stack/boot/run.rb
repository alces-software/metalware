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
require 'alces/tools/logging'
require 'alces/tools/execution'

module Alces
	module Stack
    module Boot
      class Run
        include Alces::Tools::Logging
        include Alces::Tools::Execution

        def initialize(options={})
          @node_name = options[:name]
          @group_flag = options[:group_flag]
          @gender = options[:group]
          @no_hang_flag = options[:no_hang_flag]
          @template = options[:template]
          @child_flag = options[:child]
        end

        def run!
          puts "(CTRL+C TO TERMINATE)" if !@no_hang_flag 
          begin
            if @group_flag
              run_group
            else
              run_single
            end
          rescue => e
            Alces::Stack::Boot.delete_files
            raise e
          end
        end

        def run_single
          raise "No node name supplied" if !@node_name
          ip=`gethostip -x #{@node_name} 2>/dev/null`
          raise "Could not find IP address of #{@node_name}" if ip.length < 9
          Alces::Stack::Boot.create_file(@template, ip)
          sleep if !@no_hang_flag
          Alces::Stack::Boot.delete_files if !@child_flag
        end

        def run_group
          `metal each -g #{@gender} -c 'metal boot %node% -t #{@template} --no-hang --child'`
          sleep if !@no_hang_flag
          Alces::Stack::Boot.delete_files
        end
      end
    end
  end
end
