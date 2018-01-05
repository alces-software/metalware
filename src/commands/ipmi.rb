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
require 'config'
require 'system_command'
require 'vm'

module Metalware
  module Commands
    class Ipmi < CommandHelpers::BaseCommand
      private

      prepend CommandHelpers::NodeIdentifier

      def run
        nodes.each do |node|
          ipmi(node)
        end
      end

      def ipmi(node)
        run_vm(node) if vm?(node)
        run_baremetal(node) unless vm?(node)
      end

      def run_vm(node)
        libvirt = Metalware::Vm.new(node)
        libvirt.send(args[1])
      end

      def run_baremetal(node)
        puts "#{node}: #{SystemCommand.run(command(node))}"
      end

      def command(host)
        "ipmitool -H #{host}.bmc #{render_credentials} #{render_command}"
      end

      def render_command
        options.command
      end

      def render_credentials
        object = options.group ? group : node
        raise MetalwareError, "BMC network not defined for #{object.name}" unless object.config.networks.bmc.defined
        bmc_config = object.config.networks.bmc
        "-U #{bmc_config.bmcuser} -P #{bmc_config.bmcpassword}"
      end

      def group
        alces.groups.find_by_name(args[0])
      end

      def node
        alces.nodes.find_by_name(node_names[0])
      end

      def node_names
        @node_names ||= nodes.map(&:name)
      end

      def libvirt_host(node)
        node.config.libvirt_host
      end

      def vm?(node)
        node.config.is_vm
      end
    end
  end
end
