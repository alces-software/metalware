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

      def setup; end

      def run
        if options.group
          node_names.each do |node|
            if vm?
              libvirt_run(libvirt_info[:host], node)
            else
              puts "#{node}: #{SystemCommand.run(command(node))}"
            end
          end
        elsif vm?
          libvirt_run(libvirt_info[:host], node.name)
        else
          puts "#{node.name}: #{SystemCommand.run(command(node.name))}"
        end
      end

      def libvirt_run(host, node)
        libvirt = Metalware::Vm.new(host, node)
        libvirt.run(args[1])
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

      def libvirt_info
        object = options.group ? group : node
        {
          host: object.answer.libvirt_host,
          vm: object.answer.is_vm,
        }
      end

      def vm?
        libvirt_info[:vm]
      end
    end
  end
end