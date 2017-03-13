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

        def initialize(options = {})
          @opt = Options.new(options)
          @to_delete = []
          @to_delete_dry_run = []
        end

        class Options
          def initialize(options = {})
            @options = options
          end

          def finder
            @finder ||= Alces::Stack::Templater::Finder.new(
              "#{ENV['alces_BASE']}/etc/templates/boot/",
              @options[:template])
          end

          def ks_finder
            @ks_finder ||= @options[:kickstart] ?
              Alces::Stack::Templater::Finder.new(
                "#{ENV['alces_BASE']}/etc/templates/kickstart/",
                @options[:kickstart])
              : nil
          end

          def template_parameters
            @template_parameters ||= {
              firstboot: true,
              permanentboot: permanent_boot?,
              kernelappendoptions: kernel_append.chomp
            }.tap do |h|
              h[:nodename] =
                @options[:nodename].chomp if @options[:nodename]
            end
          end

          def group
            @options[:group]
          end

          def save_loc_kickstart
            permanent_boot? ? "/var/www/html/ks" : "/var/lib/metalware/rendered/ks"
          end

          def dry_run?
            !!@options[:dry_run_flag]
          end

          def permanent_boot?
            !!@options[:permanent_boot_flag]
          end

          def kickstart?
            !!@options[:kickstart]
          end

          SCRIPT_TEMP_LOC = "#{ENV['alces_BASE']}/etc/templates/scripts"
          def scripts?
            !!@options[:script]
          end
          
          def each_script(&block)
            script = @options[:scripts].is_a? Array ? 
                       @options[:scripts] : [@options[:scripts]]
            script.each do |s|
              yield Alces::Stack::Templater::Finder.new(SCRIPT_TEMP_LOC, s)
            end
          end

          def method_missing(s, *a, &b)
            if @options.key?(s)
              @options[s]
            else
              super
            end
          end       
        end

        def run!
          puts "(CTRL+C TO TERMINATE)"
          if !@opt.template_parameters.key?(:nodename) and !@opt.group and !@opt.json 
            raise "Requires a node name, node group, or json input" 
          end

          render_kickstart if @opt.kickstart?
          render_scripts if @opt.scripts.included?

          if @opt.dry_run?
            lambda_proc = -> (parameter) { puts_template(parameter) }
          else
            lambda_proc = -> (parameter) { save_template(parameter) }
          end
          Alces::Stack::Iterator.run(@opt.group,
                                     lambda_proc,
                                     @opt.template_parameters)

          @opt.kickstart? ? kickstart_teardown : sleep
        rescue StandardError => @e
        ensure
          @e ||= Interrupt
          STDERR.print "Exiting...."
          teardown(@e)
          STDERR.puts "Done"
          $stdout.flush
          Kernel.exit(0)
        end

        def get_save_file(combiner)
          ip=`gethostip -x #{combiner.parsed_hash[:nodename]} 2>/dev/null`
          raise "Could not find IP address of #{combiner.parsed_hash[:nodename]}" if ip.length < 9
          return "/var/lib/tftpboot/pxelinux.cfg/#{ip}".chomp
        end

        def save_template(parameters={})
          add_kickstart(parameters) if @opt.kickstart?
          combiner = Alces::Stack::Templater::Combiner.new(@json, parameters)
          save = get_save_file(combiner)
          unless @opt.permanent_boot?
            @to_delete << save
          end
          combiner.save(@opt.finder.template, save)
        end

        def puts_template(parameters={})
          add_kickstart(parameters) if @opt.kickstart?
          combiner = Alces::Stack::Templater::Combiner.new(@opt.json, parameters)
          save = get_save_file(combiner)
          @to_delete_dry_run <<  save
          puts "BOOT TEMPLATE"
          unless @opt.permanent_boot?
            puts "Would save file to: " << save << "\n"
          end
          puts combiner.file(@opt.finder.template)
          puts
        end

        def add_files_to_delete(array)
          array = [array] unless array.is_a? Array
          unless @opt.permanent_boot?
            @to_delete_dry_run.concat(array) if @opt.dry_run?
            @to_delete.concat(array) unless @opt.dry_run?
          end
        end

        def render_scripts
          puts 
        end

        def add_kickstart(parameters={})
          ks_file = @opt.ks_finder.filename_diff_ext("ks")
          ks_file << "." << parameters[:nodename]
          parameters[:kickstart] = ks_file
        end

        def render_kickstart
          kickstart_options = {
            group: false,
            dry_run_flag: @opt.dry_run?,
            ran_from_boot: true,
            json: @opt.json,
            save_location: @opt.save_loc_kickstart
          }
          kickstart_options[:nodename] =
            @opt.template_parameters[:nodename] if @opt.template_parameters.key?(:nodename)
          
          kickstart_lambda = -> (hash) {
            hash[:save_append] = hash[:nodename]
            return Alces::Stack::Kickstart::Run.new(@opt.kickstart, hash).run!
          }
          
          kickstart_files = Alces::Stack::Iterator.run(@opt.group,
                                                       kickstart_lambda,
                                                       kickstart_options)
          add_files_to_delete(kickstart_files)
        end

        def kickstart_teardown
          # Deletes old signal files
          delete_lambda = -> (options) {
            `rm -f /var/lib/metalware/cache/metalwarebooter.#{options[:nodename]}`
          }
          Alces::Stack::Iterator.run(@opt.group,
                                     delete_lambda,
                                     @opt.template_parameters)

          # Switches to permanent boot
          @opt.template_parameters[:firstboot] = false
          @found_nodes = {}

          lambda_proc = -> (options) {
            if !@found_nodes[options[:nodename]] and
               File.file?("/var/lib/metalware/cache/metalwarebooter." \
                            "#{options[:nodename]}")
              @found_nodes[options[:nodename]] = true
              puts "Found #{options[:nodename]}"
              ip = `gethostip -x #{options[:nodename]} 2>/dev/null`.chomp
              `rm -f /var/lib/metalware/cache/metalwarebooter.#{options[:nodename]}`
              unless @opt.permanent_boot? 
                `rm -f /var/lib/tftpboot/pxelinux.cfg/#{ip} 2>/dev/null`
                run_str = "rm -f #{@save_loc_kickstart}/" \
                          "#{@opt.ks_finder.filename_diff_ext("ks")}." \
                          "#{options[:nodename]} 2>/dev/nul"
                `#{run_str}`
              else
                if @opt.dry_run?
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
            sleep 10
            Alces::Stack::Iterator.run(@opt.group,
                                       lambda_proc,
                                       @opt.template_parameters)
          end
          puts "Found all nodes"
          return
        end

        def teardown(e)
          tear_down_flag_dry = false
          tear_down_flag = false
          tear_down_flag_dry = true if @opt.dry_run? and !@to_delete.empty?
          tear_down_flag = true if !@opt.dry_run? and !@to_delete_dry_run.empty?
          unless @opt.permanent_boot?
            STDERR.puts "DRY RUN: Files that would be deleted:" unless @to_delete_dry_run.empty?
            @to_delete_dry_run.each { |file| STDERR.puts "  #{file}" }
            @to_delete.each { |file| `rm -f #{file} 2>/dev/null` }
          end
          raise e
        rescue Interrupt
          raise TearDownError.new(
            "Files created during a dry run") if tear_down_flag_dry
          raise TearDownError.new(
            "Files should have been saved! This was not a dry run") if tear_down_flag
        end
        class TearDownError < StandardError
        end
      end
    end
  end
end
