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
    module Hosts
      class CLI
        include Alces::Tools::CLI

        root_only
        name 'metal hosts'
        description "Modifies the hosts file"
        log_to File.join(Alces::Stack.config.log_root,'alces-node-ho.log')

        flag    :add_flag,
                'Adds a new entry to /etc/hosts',
                '--add', '-a',
                default: false

        option  :template,
                'Template file to be used',
                '--template', '-t',
                default: "#{ENV['alces_BASE']}/etc/templates/hosts/compute.erb"

        flag    :template_options,
                'Show templating options',
                '--template-options',
                default: false

        option  :nodename,
                'Node name to be modified',
                '--nodename',
                default: ""

        option  :nodegroup,
                'Node group to be modified, overrides --nodename',
                '--nodegroup', '-g',
                default: false

        option  :iptail,
                'Fourth IP byte in template',
                '--iptail',
                default: ""

        option  :q3,
                'Replaces q3 in template',
                '--q3',
                default: ""

        option  :json,
                'JSON file or string containing additional templating parameters',
                '--additional-parameters', '-j',
                default: false

        def setup_signal_handler
          trap('INT') do
            STDERR.puts "\nExiting..." unless @exiting
            @exiting = true
            Kernel.exit(0)
          end
        end

        def show_template_options
          options = {
            JSON: true,
            nodename: "Value specified by --nodename",
            iptail: "Value specified by --iptail",
            q3: "Value specified by --q3"
          }
          Alces::Stack::Templater.show_options(options)
          exit 0
        end

        def execute
          setup_signal_handler
          show_template_options if template_options

          Alces::Stack::Hosts.run!(template, 
              add_flag: add_flag,
              nodename: nodename,
              nodegroup: nodegroup,
              iptail: iptail,
              q3: q3,
              json: json
            )
        end
      end
    end
  end
end