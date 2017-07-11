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

require 'yaml'

require 'output'


module Metalware
  class HunterUpdater
    def initialize(hunter_file)
      @hunter_file = hunter_file
    end

    def add(node_name, mac_address)
      node_name = node_name.to_sym

      current_yaml = Data.load(@hunter_file)
      remove_colliding_entries!(current_yaml, node_name, mac_address)

      new_yaml = current_yaml.merge({
        node_name.to_sym => mac_address
      })
      Data.dump(@hunter_file, new_yaml)
    end

    private

    def remove_colliding_entries!(current_yaml, new_node_name, new_mac_address)
      node_name_present = current_yaml.keys.include?(new_node_name)
      mac_address_present = current_yaml.values.include?(new_mac_address)

      if node_name_present
        existing_mac_address = current_yaml[new_node_name]

        Output.stderr \
          "Replacing existing entry for #{new_node_name} " +
          "(existing entry has MAC address #{existing_mac_address})."

      elsif mac_address_present
        existing_node_name = current_yaml.invert[new_mac_address]

        Output.stderr \
          "Replacing existing entry with MAC address #{new_mac_address} " +
          "(existing entry for node #{existing_node_name})."

        current_yaml.reject! do |_, mac_address|
          mac_address == new_mac_address
        end
      end
    end
  end
end
