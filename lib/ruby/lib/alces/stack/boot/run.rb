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
          @template = Alces::Stack::Templater::Finder.new("#{ENV['alces_BASE']}/etc/templates/boot/").find(options[:template])
          @group = options[:group]
          @dry_run_flag = options[:dry_run_flag]
          @template_parameters = {
            kernelappendoptions: options[:kernel_append].chomp
          }
          @template_parameters[:nodename] = options[:nodename].chomp if options[:nodename]
          @json = options[:json]
          @kickstart = options[:kickstart]
          @delete_pxe = ""
        end

        def run!
          puts "(CTRL+C TO TERMINATE)"
          raise "Requires a node name, node group, or json input" if !@template_parameters.key?("nodename".to_sym) and !@group and !@json 

          #Generates kick start files if required
          if !@kickstart.to_s.empty?
            set_kickstart_template_parameter

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

          case 
          when @dry_run_flag
            lambda = -> (json) {puts_template(json)}
          else
            lambda = -> (json) {save_template(json)}
          end

          begin
            Alces::Stack::Iterator.new(@group, lambda, @json)
            sleep
          rescue Exception => e
            puts "Would delete the following files:" if @dry_run_flag
            @delete_pxe.split(',').each do |s|
              next if s.empty?
              if @dry_run_flag then puts "  /var/lib/tftpboot/pxelinux.cfg/#{s}"
              else `rm -f /var/lib/tftpboot/pxelinux.cfg/#{s} 2>/dev/null`
              end
            end
            if @kickstart
              @kickstart_files.each do |fname|
                if @dry_run_flag then puts "  #{fname}"
                else `rm -f #{fname} 2>/dev/null`
                end
              end
            end
            raise e
          rescue Interrupt
          end
        end

        def save_template(json)
          hash = Alces::Stack::Templater::JSON_Templater.parse(json, @template_parameters)
          ip=`gethostip -x #{hash[:nodename]} 2>/dev/null`
          raise "Could not find IP address of #{hash[:nodename]}" if ip.length < 9
          @delete_pxe << ",#{ip}"
          save="/var/lib/tftpboot/pxelinux.cfg/#{ip}"
          Alces::Stack::Templater.save(@template, save, hash)
        end

        def puts_template(json)
          hash = Alces::Stack::Templater::JSON_Templater.parse(json, @template_parameters)
          ip=`gethostip -x #{hash[:nodename]} 2>/dev/null`
          raise "Could not find IP address of #{hash[:nodename]}" if ip.length < 9
          @delete_pxe << ",#{ip}"
          save="/var/lib/tftpboot/pxelinux.cfg/#{ip}"
          puts "BOOT TEMPLATE"
          puts "Would save file to: " << save << "\n"
          puts Alces::Stack::Templater.file(@template, hash)
          puts
        end

        def run_kickstart(json)
          # Creates the json input for kickstart]
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
          name = @kickstart.scan(/\.?\w+\.?\w*\Z/)
          raise "Could not determine kickstart file name: " << @kickstart if name.size != 1
          @template_parameters[:kickstart] = name[0].scan(/\.?\w+/)[0] << ".ks.<%= nodename %>" 
        end
      end
    end
  end
end
