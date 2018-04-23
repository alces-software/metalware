# frozen_string_literal: true

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

require 'command_helpers/base_command'
require 'command_helpers/node_identifier'
require 'system_command'
require 'vm'

module Metalware
  module Commands
    class Ipmi < CommandHelpers::BaseCommand
      Command = Struct.new(:args, :options) do
        SEE_HELP = 'Use --help for more information'

        MULTIPLE_CMDS_ERROR = <<~ERROR.squish
          Both command option and argument given but only one may be provided.
          #{SEE_HELP}
        ERROR

        NO_COMMAND_ERROR = <<~ERROR.squish
          No command given. #{SEE_HELP}
        ERROR

        def self.parse(args, options)
          new(args, options).parse
        end

        def parse
          raise InvalidInput, MULTIPLE_CMDS_ERROR if multiple_commands_given?
          raise InvalidInput, NO_COMMAND_ERROR if no_command_given?
          provided_commands.first
        end

        def multiple_commands_given?
          provided_commands.length > 1
        end

        def no_command_given?
          provided_commands.none?
        end

        def provided_commands
          [command_argument, options.command].reject(&:nil?)
        end

        def command_argument
          args[1]
        end
      end

      private

      attr_reader :command_argument

      prepend CommandHelpers::NodeIdentifier

      def setup
        @command_argument = Command.parse(args, options)
      end

      def run
        nodes.each do |node|
          ipmi(node)
          sleep options.sleep if options.sleep
        end
      end

      def ipmi(node)
        vm?(node) ? run_vm(node) : run_baremetal(node)
      end

      def run_vm(node)
        libvirt = Metalware::Vm.new(node)
        libvirt.send(command_argument)
      end

      def run_baremetal(node)
        puts "#{node.name}: #{ipmi_command_output(node)}"
      end

      def ipmi_command_output(node)
        command = ipmi_command(node, arguments: ipmi_command_arguments)
        SystemCommand.run(command)
      rescue SystemCommandError => e
        e.message
      end

      def ipmi_command(node, arguments:)
        <<~COMMAND.squish
          ipmitool -H #{node.name}.bmc -I lanplus #{render_credentials(node)}
          #{arguments}
        COMMAND
      end

      # By default the arguments passed to `ipmitool` are the same as the
      # argument passed to the `metal` command, but this may be overridden by
      # commands descended from this.
      alias ipmi_command_arguments command_argument

      def render_credentials(node)
        bmc_config = node.config&.networks&.bmc
        unless bmc_config&.defined
          raise MetalwareError, "BMC network not defined for #{node.name}"
        end
        "-U #{bmc_config.bmcuser} -P #{bmc_config.bmcpassword}"
      end

      def group
        alces.groups.find_by_name(node_identifier)
      end

      def node
        alces.nodes.find_by_name(node_identifier)
      end

      def vm?(node)
        node.config.is_vm
      end
    end
  end
end
