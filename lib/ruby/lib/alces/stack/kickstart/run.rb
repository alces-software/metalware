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
    module Kickstart
      class Run
        include Alces::Tools::Logging
        include Alces::Tools::Execution

        def initialize(template, options={})
          @template = Alces::Stack::Templater::Finder.new("#{ENV['alces_BASE']}/etc/templates/kickstart/").find(template)
          @group = options[:group]
          @json = options[:json]
          @dry_run_flag = options[:dry_run_flag]
          @template_parameters = {
            hostip: `hostname -i`.chomp
          }
          @template_parameters[:nodename] = options[:nodename].chomp if options[:nodename]
          @save_append = options[:save_append]
          @ran_from_boot = options[:ran_from_boot]
        end

        def run!
          raise "Requires json input, if no input include: -j \"{}\"" if !@json

          if @dry_run_flag
            lambda = -> (json) { puts_template(json) }
          else
            lambda = -> (json) { save(json) }
          end

          Alces::Stack::Iterator.new(@group, lambda, @json) if !lambda.nil?
          return get_file_name if @ran_from_boot
        end

        def save(json)
          save_file = get_file_name
          Alces::Stack::Templater::JSON_Templater.save(@template, save_file, json, @template_parameters)
          puts "Save file: " << save_file
        end

        def get_file_name
          name = @template.scan(/\.?\w+\.?\w*\Z/)
          raise "Could not determine save file name from template: " << @template if name.size != 1
          return "/var/www/html/deployment/ks/" << name[0].scan(/\.?\w+/)[0] << ".ks" << @save_append
        end

        def puts_template(json)
          save_file = get_file_name
          puts "KICKSTART TEMPLATE"
          puts "Would save to: " << save_file << "\n\n"
          puts Alces::Stack::Templater::JSON_Templater.file(@template, json, @template_parameters)
        end
      end
    end
  end
end
