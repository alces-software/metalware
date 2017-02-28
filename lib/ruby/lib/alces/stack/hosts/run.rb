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
require 'alces/tools/cli'
require "alces/stack/templater"
require 'alces/stack/iterator'

module Alces
  module Stack
    module Hosts
      class Run
        include Alces::Tools::Logging
        include Alces::Tools::Execution

        def initialize(template, options={})
          @template = Alces::Stack::Templater::Finder.new("#{ENV['alces_BASE']}/etc/templates/hosts/").find(template)
          @template_parameters = {
            nodename: options[:nodename]
          }
          @nodegroup = options[:nodegroup]
          @json = options[:json]
          @dry_run_flag = options[:dry_run_flag]
          @add_flag = options[:add_flag]
        end

        def run!
          raise "Requires a node name, node group, or json" if !@template_parameters[:nodename] and !@nodegroup and !@json

          case
          when @dry_run_flag
            lambda = dry_run
          when @add_flag
            lambda = -> (json) {add(json)}
          else
            raise "Could not modify hosts, see 'metal hosts -h'"
          end

          Alces::Stack::Iterator.new(@nodegroup, lambda, @json) if !lambda.nil?
        end

        def dry_run
          case
          when @add_flag
            lambda = -> (json) {puts_template(json)}
          else
            raise "Could not modify hosts, see 'metal hosts -h'"
          end
          return lambda
        end

        def add(json)
          append_file = "/etc/hosts"
          json = "" if !json
          Alces::Stack::Templater::JSON_Templater.append(@template, append_file, json, @template_parameters)
        end

        def puts_template(json)
          json = "" if !json
          puts Alces::Stack::Templater::JSON_Templater.file(@template, json, @template_parameters)
        end
      end
    end
  end
end
