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
require 'alces/stack/log'

module Alces
  module Stack
    module Boot
      class CLI
        include Alces::Tools::CLI

        root_only
        name 'metal boot'
        description "Creates the boot files for the node(s)"
        log_to File.join(Alces::Stack.config.log_root,'alces-node-boot.log')

        option  :nodename,
                'Node name to be modified',
                '-n', '--node-name',
                default: false

        option  :group,
                'Specify a gender group to run over',
                '-g', '--node-group',
                default: false

        option  :json,
                'JSON string containing additional templating parameters',
                '-j', '--additional-parameters',
                default: false

        option  :kernel_append,
                'Specify value for kernel append in template. Check --template-options',
                '--kernelappendoptions',
                default: ""

        option  :repo,
                'Specifies a repo to use for all templates. Is overridden by <repo>:: flag',
                '-r', '--repo'

        option  :template,
                'Specify template',
                '-t', '--template',
                default: "install.erb"

        flag    :permanent_boot_flag,
                'Causes the pxe and kickstart files remain after completion',
                '-p', '--permanent',
                default: false

        flag    :template_options,
                'Show templating options',
                '--template-options',
                default: false

        option  :kickstart,
                'Renders the kickstart template if include. Deletes the file at the end',
                '-k', '--kickstart'

        option  :scripts,
                'Renders script templates, saved in default location. Format: comma separated string',
                '-s', '--scripts'

        flag    :dry_run_flag,
                'Prints the template output without modifying files',
                '-x', '--dry-run',
                default: false

        def show_template_options
          options = {
            nodename: "Value specified by --node-name",
            kernelappendoptions: "Value specified by --kernelappendoptions",
            kickstart: "Determined from --kickstart (required) and nodename",
            firstboot: "True by default, switches to false on second render if --permanent is specified"
          }
          Alces::Stack::Templater.show_options(options)
          exit 0
        end

        def assert_preconditions!
          Alces::Stack::Log.progname = "boot"
          Alces::Stack::Log.info "metal boot #{ARGV.to_s.gsub(/[\[\],\"]/, "")}"
          self.class.assert_preconditions!
        end

        def execute
          show_template_options if template_options
          Alces::Stack::Boot.run!(
              nodename: nodename,
              group: group,
              template: template,
              kernel_append: kernel_append,
              dry_run: dry_run_flag,
              json: json,
              kickstart: kickstart,
              permanent_boot: permanent_boot_flag,
              scripts: scripts
            )
        rescue => e
          Alces::Stack::Log.fatal e.inspect
          raise e
        end
      end
    end
  end
end