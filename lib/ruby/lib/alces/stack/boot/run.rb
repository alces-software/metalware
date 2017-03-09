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
          @finder = Alces::Stack::Templater::Finder.new("#{ENV['alces_BASE']}/etc/templates/boot/", options[:template])
          @group = options[:group]
          @dry_run_flag = options[:dry_run_flag]
          @permanent_boot_flag = options[:permanent_boot_flag]
          @template_parameters = {
            firstboot: true,
            permanentboot: @permanent_boot_flag,
            kernelappendoptions: options[:kernel_append].chomp
          }
          @template_parameters[:nodename] = options[:nodename].chomp if options[:nodename]
          @json = options[:json]
          @kickstart_template = options[:kickstart]
          @ks_finder = Alces::Stack::Templater::Finder.new("#{ENV['alces_BASE']}/etc/templates/kickstart/", @kickstart_template) if @kickstart_template
          @to_delete = []
          @to_delete_dry_run = []
          @save_loc_kickstart = @permanent_boot_flag ? "/var/www/html/ks" : "/var/lib/metalware/rendered/ks"
          `mkdir -p #{@save_loc_kickstart} 2>/dev/null`
        end

        def run!
          puts "(CTRL+C TO TERMINATE)"
          raise "Requires a node name, node group, or json input" if !@template_parameters.key?("nodename".to_sym) and !@group and !@json 

          #Generates kick start files if required
          run_kickstart if !@kickstart_template.to_s.empty?

          if @dry_run_flag
            lambda_proc = -> (parameter) {puts_template(parameter)}
          else
            lambda_proc = -> (parameter) {save_template(parameter)}
          end

          Alces::Stack::Iterator.run(@group, lambda_proc, @template_parameters)
          if !@kickstart_template.to_s.empty?
            kickstart_teardown
            raise Interrupt
          else sleep
          end
        rescue Exception => e
          print "Exiting...."
          STDOUT.flush
          teardown(e)
          puts "Done"
          $stdout.flush
          Kernel.exit(0)
        end

        def get_save_file(combiner)
          ip=`gethostip -x #{combiner.parsed_hash[:nodename]} 2>/dev/null`
          raise "Could not find IP address of #{combiner.parsed_hash[:nodename]}" if ip.length < 9
          return "/var/lib/tftpboot/pxelinux.cfg/#{ip}".chomp
        end

        def save_template(parameters={})
          add_kickstart(parameters) if @kickstart_template
          combiner = Alces::Stack::Templater::Combiner.new(@json, parameters)
          save = get_save_file(combiner)
          if !@permanent_boot_flag
            @to_delete << save
          end
          combiner.save(@finder.template, save)
        end

        def puts_template(parameters={})
          add_kickstart(parameters) if @kickstart_template
          combiner = Alces::Stack::Templater::Combiner.new(@json, parameters)
          save = get_save_file(combiner)
          @to_delete_dry_run <<  save
          puts "BOOT TEMPLATE"
          if !@permanent_boot_flag
            puts "Would save file to: " << save << "\n"
          end
          puts combiner.file(@finder.template)
          puts
        end

        def add_kickstart(parameters={})
          ks_file = @ks_finder.filename_diff_ext("ks")
          ks_file << "." << parameters[:nodename]
          parameters[:kickstart] = ks_file
        end

        def run_kickstart
          kickstart_options = {
            group: false,
            dry_run_flag: @dry_run_flag,
            ran_from_boot: true,
            json: @json,
            save_location: @save_loc_kickstart
          }
          kickstart_options[:nodename] = @template_parameters[:nodename] if @template_parameters.key?("nodename".to_sym)
          kickstart_lambda = -> (hash) {
            hash[:save_append] = hash[:nodename]
            return Alces::Stack::Kickstart::Run.new(@kickstart_template, hash).run!
          }
          kickstart_files = Alces::Stack::Iterator.run(@group, kickstart_lambda, kickstart_options)
          kickstart_files
          if !@permanent_boot_flag
            @to_delete_dry_run.push(*kickstart_files) if @dry_run_flag
            @to_delete.push(*kickstart_files) if !@dry_run_flag
          end
        end

        def kickstart_teardown
          # Deletes old signal files
          delete_lambda = -> (options) { `rm -f /var/lib/metalware/cache/metalwarebooter.#{options[:nodename]}` }
          Alces::Stack::Iterator.run(@group, delete_lambda, {nodename: @template_parameters[:nodename]})

          # Switches to permanent boot
          @template_parameters[:firstboot] = false

          @found_nodes = Hash.new
          lambda_proc = -> (options) {
            if !@found_nodes[options[:nodename]] and File.file?("/var/lib/metalware/cache/metalwarebooter.#{options[:nodename]}")
              @found_nodes[options[:nodename]] = true
              puts "Found #{options[:nodename]}"
              ip = `gethostip -x #{options[:nodename]} 2>/dev/null`.chomp
              `rm -f /var/lib/metalware/cache/metalwarebooter.#{options[:nodename]}`
              if !@permanent_boot_flag
                `rm -f /var/lib/tftpboot/pxelinux.cfg/#{ip} 2>/dev/null`
                `rm -f #{@save_loc_kickstart}/#{@ks_finder.filename_diff_ext("ks")}.#{options[:nodename]} 2>/dev/null`
              else
                if @dry_run_flag
                  puts_template(options)
                else
                  save_template(options)
                end
              end
            elsif !@found_nodes[options[:nodename]]
              @kickstart_teardown_exit_flag = true
            end
          }
          @kickstart_teardown_exit_flag = true
          puts "Looking for completed nodes"
          while @kickstart_teardown_exit_flag
            @kickstart_teardown_exit_flag = false
            sleep 1
            puts "Working"
            Alces::Stack::Iterator.run(@group, lambda_proc, @template_parameters)
          end
          $stdout.flush
          sleep 10
          puts "Found all nodes"
          $stdout.flush
          return
        end

        def teardown(e)
          tear_down_flag_dry = false
          tear_down_flag = false
          tear_down_flag_dry = true if @dry_run_flag and !@to_delete.empty?
          tear_down_flag = true if !@dry_run_flag and !@to_delete_dry_run.empty?
          if !@permanent_boot_flag
            puts "DRY RUN: Files that would be deleted:" if !@to_delete_dry_run.empty?
            @to_delete_dry_run.each do |file| puts "  #{file}" end
            puts @to_delete
            @to_delete.each do |file| `rm -f #{file} 2>/dev/null` end
          end
          raise e
        rescue Interrupt
          raise TearDownError.new("Files created during a dry run") if tear_down_flag_dry
          raise TearDownError.new("Files should have been saved! This was not a dry run") if tear_down_flag
        end
        class TearDownError < StandardError
        end
      end
    end
  end
end
