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
          nodes.each do |node|
            create(node)
          end
        end

        def create(node)
          libvirt = Metalware::Vm.new(node)
          libvirt.create
          hunter_updater.add(node.name, node.config.vm_mac_address_build)
        end

        def hunter_updater
          @hunter_updater ||= HunterUpdater.new(Constants::HUNTER_PATH)
        end
      end
    end
  end
end
