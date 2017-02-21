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
require 'alces/stack/nodes'
require "alces/stack/templater"

module Alces
  module Stack
    module Hosts
      class Run
        include Alces::Tools::Logging
        include Alces::Tools::Execution

        def initialize(template, options={})
          @template = template
          @template_parameters = {
            nodename: options[:nodename],
            iptail: options[:iptail],
            q3: options[:q3]
          }
          @json = options[:json]
          @add_flag = options[:add_flag]
        end

        def run!
          add() if @add_flag
        end

        def add
          append_file = "/etc/hosts"
          if !@json
            Alces::Stack::Templater.append(@template, append_file, @template_parameters)
          else
            Alces::Stack::Templater::JSON_Templater.append(@template, append_file, @json, @template_parameters)
          end
        end
      end
    end
  end
end
