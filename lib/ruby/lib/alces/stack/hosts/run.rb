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
require "alces/stack/templater"
require "alces/stack/finder"
require 'alces/stack/iterator'

module Alces
  module Stack
    module Hosts
      class Run
        include Alces::Tools::Execution

        def initialize(template, options={})
          @finder = 
            Alces::Stack::Finder.new("#{ENV['alces_REPO']}", "/templates/hosts/", template)
          @template_parameters = {
            nodename: options[:nodename]
          }
          @nodegroup = options[:nodegroup]
          @json = options[:json] ? options[:json] : ""
          @dry_run_flag = options[:dry_run_flag]
          @add_flag = options[:add_flag]
        end

        def run!
          raise "Requires a node name, node group, or json" if !@template_parameters[:nodename] &&
                                                               !@nodegroup &&
                                                               @json.empty?

          case
          when @dry_run_flag
            lambda_proc = dry_run
          when @add_flag
            lambda_proc = -> (template_parameters) {add(template_parameters)} 
          end

          Alces::Stack::Iterator.run(@nodegroup, lambda_proc, @template_parameters) if !lambda_proc.nil?
          raise "Could not modify hosts! No command included (e.g. --add).\nSee 'metal hosts -h'" if lambda_proc.nil?
        end

        def dry_run
          case
          when @add_flag
            lambda_proc = -> (template_parameters) {puts_template(template_parameters)}
          end
          return lambda_proc
        end

        def add(template_parameters)
          append_file = "/etc/hosts"
          Alces::Stack::Templater::Combiner.new(@finder.repo, @json, template_parameters).append(@finder.template, append_file)
        end

        def puts_template(template_parameters)
          puts Alces::Stack::Templater::Combiner.new(@finder.repo, @json, template_parameters).file(@finder.template)
        end
      end
    end
  end
end
