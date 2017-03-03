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
require 'alces/stack/iterator'
require "alces/stack/templater"
require 'alces/stack/kickstart'
require 'json'

module Alces
  module Stack
    module Boot
      class Run
        include Alces::Tools::Logging
        include Alces::Tools::Execution

        def initialize(options={})
          @finder = Alces::Stack::Templater::Finder.new("#{ENV['alces_BASE']}/etc/templates/boot/")
          @finder.template = options[:template]
          @group = options[:group]
          @dry_run_flag = options[:dry_run_flag]
          @template_parameters = {
            kernelappendoptions: options[:kernel_append].chomp
          }
          @template_parameters[:nodename] = options[:nodename].chomp if options[:nodename]
          @json = options[:json]
          @kickstart = options[:kickstart]
          @to_delete = Array.new
          @to_delete_dry_run = Array.new
        end

        def run!
          puts "(CTRL+C TO TERMINATE)"
          raise "Requires a node name, node group, or json input" if !@template_parameters.key?("nodename".to_sym) and !@group and !@json 

          #Generates kick start files if required
          set_kickstart_template_parameter if !@kickstart.to_s.empty?

          case 
          when @dry_run_flag
            lambda = -> (parameter) {puts_template(parameter)}
          else
            lambda = -> (parameter) {save_template(parameter)}
          end

          begin
            Alces::Stack::Iterator.new(@template_parameters, lambda)
            kickstart_teardown if !@kickstart.to_s.empty?
            sleep
          rescue Exception => e
            teardown(e)
          end
        end

        def get_save_file(combiner)
          ip=`gethostip -x #{combiner.parsed_hash[:nodename]} 2>/dev/null`
          raise "Could not find IP address of #{combiner.parsed_hash[:nodename]}" if ip.length < 9
          return "/var/lib/tftpboot/pxelinux.cfg/#{ip}".chomp
        end

        def save_template(parameters={})
          combiner = Alces::Stack::Templater::Combiner.new(@json, parameters)
          save = get_save_file(combiner)
          @to_delete << save
          combiner.save(@finder.template, save)
        end

        def puts_template(parameters={})
          combiner = Alces::Stack::Templater::Combiner.new(@json, parameters)
          save = get_save_file(combiner)
          @to_delete_dry_run <<  save
          puts "BOOT TEMPLATE"
          puts "Would save file to: " << save << "\n"
          puts combiner.file(@finder.template)
          puts
        end

        def run_kickstart(json)
          # Creates the json input for kickstart
          json_new = {}
          json_new.merge!(@template_parameters)
          if json and !json.to_s.empty?
            json_old = JSON.parse(json)
            json_new.merge!(json_old)
          end
          json_new = json_new.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
          
          # Sets dynamic variables in the kickstart options
          @kickstart_options[:nodename] = json_new[:nodename] if json_new.key?("nodename".to_sym)
          raise "No node specified for appending kickstart file" if !@kickstart_options.key?("nodename".to_sym)
          @kickstart_options[:save_append] = "." << @kickstart_options[:nodename]
          @kickstart_options[:json] = json_new.to_json
          @kickstart_files << Alces::Stack::Kickstart.run!(@kickstart, @kickstart_options)
          puts "\n" if @dry_run_flag
        end

        def set_kickstart_template_parameter
          @kickstart = Alces::Stack::Templater::Finder.new("#{ENV['alces_BASE']}/etc/templates/kickstart/").find(@kickstart)
          @kickstart_name = @kickstart.scan(/\.?\w+\.?\w*\Z/)
          raise "Could not determine kickstart file name: #{@kickstart}" if @kickstart_name.size != 1
          @kickstart_name = @kickstart_name[0].scan(/\.?\w+/)[0] << ".ks"
          @template_parameters[:kickstart] = "#{@kickstart_name}.<%= nodename %>" 
        
          @kickstart_options = {
            group: false,
            dry_run_flag:  @dry_run_flag,
            ran_from_boot: true
          }
          @kickstart_options[:nodename] = @template_parameters[:nodename] if @template_parameters.key?("nodename".to_sym)
          kickstart_lambda = -> (json) {run_kickstart(json)}
          @kickstart_files = Array.new
          Alces::Stack::Iterator.new(@group, kickstart_lambda, @json)
        end

        def kickstart_teardown
          # Deletes old signal files
          delete_lambda = -> (options) { `rm -f /var/lib/metalware/cache/metalwarebooter.#{options[:nodename]}` }
          Alces::Stack::Iterator.run(@group, delete_lambda, {nodename: @template_parameters[:nodename]})
          # 
          @found_nodes = Hash.new
          lambda = -> (options) {
            if !@found_nodes[options[:nodename]] and File.file?("/var/lib/metalware/cache/metalwarebooter.#{options[:nodename]}")
              @found_nodes[options[:nodename]] = true
              puts "Found #{options[:nodename]}"
              ip = `gethostip -x #{options[:nodename]} 2>/dev/null`.chomp
              `rm -f /var/lib/tftpboot/pxelinux.cfg/#{ip} 2>/dev/null`
              `rm -f /var/lib/metalware/rendered/ks/#{@kickstart_name}.#{options[:nodename]} 2>/dev/null`
              `rm -f /var/lib/metalware/cache/metalwarebooter.#{options[:nodename]}`
            elsif !@found_nodes[options[:nodename]]
              @kickstart_teardown_exit_flag = true
            end
          }
          @kickstart_teardown_exit_flag = true
          puts "Looking for completed nodes"
          while @kickstart_teardown_exit_flag
            @kickstart_teardown_exit_flag = false
            sleep 30
            Alces::Stack::Iterator.run(@group, lambda, {nodename: @template_parameters[:nodename]})
          end
          puts "Found all nodes"
          return
        end

        def teardown(e)
          tear_down_flag_dry = false
          tear_down_flag = false
          tear_down_flag_dry = true if @dry_run_flag and !@to_delete.empty?
          tear_down_flag = true if !@dry_run_flag and !@to_delete_dry_run.empty?
          puts "DRY RUN: Files that would be deleted:" if !@to_delete_dry_run.empty?
          @to_delete_dry_run.each do |file| puts "  #{file}" end
          @to_delete_dry.each do |file| `rm -f #{file}` end
          begin
            raise e
          rescue Interrupt
            raise TearDownError.new("Files created during a dry run") if tear_down_flag_dry
            raise TearDownError.new("Files should have been saved! This was not a dry run") if tear_down_flag
          end
        end
        class TearDownError < StandardError
        end
      end
    end
  end
end
