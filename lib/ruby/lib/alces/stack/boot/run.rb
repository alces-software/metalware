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

module Alces
  module Stack
    module Boot
      class Run
        include Alces::Tools::Logging
        include Alces::Tools::Execution

        def initialize(options={})
          @template = options[:template]
          @group = options[:group]
          @dry_run_flag = options[:dry_run_flag]
          @template_parameters = {
            hostip: `hostname -i`.chomp,
            nodename: false,
            kernelappendoptions: options[:kernel_append].chomp
          }
          @template_parameters[:nodename] = options[:nodename].chomp if options[:nodename]
          @json = options[:json]
          @delete_node = ""
        end

        def run!
          puts "(CTRL+C TO TERMINATE)"
          raise "Requires a node name, node group, or json input" if !@node_name and !@group and !@json 

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
            if @dry_run_flag
              puts "Would delete the following files:"
              @delete_node.split(',').each do |s|
                next if s.empty?
                puts "  /var/lib/tftpboot/pxelinux.cfg/#{s}"
              end
            else
              @delete_node.split(',').each do |s|
                next if s.empty?
                `rm -f /var/lib/tftpboot/pxelinux.cfg/#{s} 2>/dev/null`
              end
            end
            raise e
          end
        end

        def save_template(json)
          hash = Alces::Stack::Templater::JSON_Templater.parse(json, @template_parameters)
          ip=`gethostip -x #{hash[:nodename]} 2>/dev/null`
          raise "Could not find IP address of #{hash[:nodename]}" if ip.length < 9
          @delete_node << ",#{ip}"
          save="/var/lib/tftpboot/pxelinux.cfg/#{ip}"
          Alces::Stack::Templater.save(@template, save, hash)
        end

        def puts_template(json)
          hash = Alces::Stack::Templater::JSON_Templater.parse(json, @template_parameters)
          ip=`gethostip -x #{hash[:nodename]} 2>/dev/null`
          raise "Could not find IP address of #{hash[:nodename]}" if ip.length < 9
          @delete_node << ",#{ip}"
          save="/var/lib/tftpboot/pxelinux.cfg/#{ip}"
          puts "Would save file to: " << save
          puts Alces::Stack::Templater.file(@template, hash)
          puts
        end
      end
    end
  end
end
