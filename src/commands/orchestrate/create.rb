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

require 'constants'
require 'command_helpers/orchestrate_command'
require 'hunter_updater'

module Metalware
  module Commands
    module Orchestrate
      class Create < CommandHelpers::OrchestrateCommand
        private

        def run
          if options.group
            nodes.each do |node|
              create(node)
            end
          else
            create(node)
          end
        end

        def create(node)
          libvirt = Metalware::Vm.new(node_info[:libvirt_host], node.name, 'vm')
          libvirt.create(render_template(node.name, 'disk'), render_template(node.name, 'vm'))
          hunter_updater.add(node.name, node.answer.vm_mac_address_build)
        end

        def hunter_updater
          @hunter_updater ||= HunterUpdater.new(Constants::HUNTER_PATH)
        end

        def render_template(node_name, type)
          path = "/var/lib/metalware/repo/libvirt/#{type}.xml"
          node = alces.nodes.find_by_name(node_name)
          templater = node ? node : alces
          templater.render_erb_template(File.read(path))
        end
      end
    end
  end
end
