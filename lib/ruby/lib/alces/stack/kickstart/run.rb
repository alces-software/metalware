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
require 'alces/stack/iterator'

module Alces
  module Stack
    module Kickstart
      class Run
        include Alces::Tools::Execution

        def initialize(template, options={})
          @finder = Alces::Stack::Templater::Finder.new("#{ENV['alces_BASE']}/etc/templates/kickstart/", template)
          @group = options[:group]
          @json = options[:json]
          @dry_run_flag = options[:dry_run_flag]
          @template_parameters = {}
          @template_parameters[:nodename] = options[:nodename].chomp if options[:nodename]
          @save_append = options[:save_append]
          @ran_from_boot = options[:ran_from_boot]
          @save_location = "#{options[:save_location]}"
          @save_location << "/" if @save_location[-1] != "/"
        end

        def run!
          raise "Ran from boot can only run with a single node" if @ran_from_boot and @group
          if @dry_run_flag
            lambda_proc = -> (template_parameters) { puts_template(template_parameters) }
          else
            lambda_proc = -> (template_parameters) { save_template(template_parameters) }
          end

          Alces::Stack::Iterator.run(@group, lambda_proc, @template_parameters)
          return if !@ran_from_boot
          get_save_file(@template_parameters[:nodename])
        end

        def get_save_file(nodename)
          str = "#{@save_location}" << @finder.filename_diff_ext("ks")
          str << "." << @save_append if !@save_append.to_s.empty? and @save_append
          str << "." << nodename.to_s if !@group.to_s.empty? and @group
          return str
        end

        def save_template(template_parameters)
          combiner = Alces::Stack::Templater::Combiner.new(@json, template_parameters)
          combiner.save(@finder.template, get_save_file(combiner.parsed_hash[:nodename]))
        end

        def puts_template(template_parameters)
          combiner = Alces::Stack::Templater::Combiner.new(@json, template_parameters)
          puts "KICKSTART TEMPLATE"
          puts "Hash:" << combiner.parsed_hash.to_s
          puts "Save: " << get_save_file(combiner.parsed_hash[:nodename])
          puts "Template:"
          puts combiner.file(@finder.template)
        end
      end
    end
  end
end
