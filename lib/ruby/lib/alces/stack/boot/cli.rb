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
require 'alces/tools/cli'
require 'alces/stack'
require "alces/stack/templater"

module Alces
  module Stack
    module Boot
      class CLI
        include Alces::Tools::CLI

        root_only
        name 'metal boot [NODE NAME]'
        description "Creates the boot files for the node(s)"
        log_to File.join(Alces::Stack.config.log_root,'alces-node-boot.log')

        option  :group,
                'Specify a gender group to run over',
                '--group', '-g',
                default: false

        option  :template,
                'Specify path to template for pxelinux.cfg',
                '--template', '-t',
                default: "#{ENV['alces_BASE']}/etc/templates/pxelinux.cfg/localboot.erb"

        flag    :template_options,
                'Show templating options',
                '--template-options',
                default: false

        option  :kernel_append,
                'Specify value for kernal append in template. Check --template-options',
                '--kernelappendoptions',
                default: ""

        def setup_signal_handler
          trap('INT') do
            STDERR.puts "\nExiting..." unless @exiting
            @exiting = true
            Kernel.exit(0)
          end
        end

        def show_template_options
          options = {
            :hostip => "Head node IP address",
            :node => "Compute node's name",
            :kernelappendoptions => "Value specified by --kernelappendoptions"
          }
          Alces::Stack::Templater.show_options(options)
          exit 0
        end

        def execute
          setup_signal_handler

          show_template_options if template_options

          name = ARGV[0] if !group
          Alces::Stack::Boot.run!(
            name: name,
            group_flag: !(group == false),
            group: group,
            template: template,
            kernel_append: kernel_append
            )
        end
      end
    end
  end
end