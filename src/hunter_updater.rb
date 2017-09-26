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

require 'yaml'

require 'output'

module Metalware
  class HunterUpdater
    def initialize(hunter_file)
      @hunter_file = hunter_file
    end

    def add(node_name, mac_address)
      node_name = node_name.to_sym
      new_yaml = update_hunter_yaml(node_name, mac_address)
      Data.dump(hunter_file, new_yaml)
    end

    private

    attr_reader :hunter_file

    def update_hunter_yaml(new_node_name, new_mac_address)
      current_yaml = load_current_yaml
      notify_user_about_update(current_yaml, new_node_name, new_mac_address)

      # Associate new node name and MAC address, replacing any existing
      # association.
      current_yaml
        .reject { |_, mac_address| mac_address == new_mac_address }
        .merge(new_node_name => new_mac_address)
    end

    def load_current_yaml
      Data.load(hunter_file)
    end

    def notify_user_about_update(current_yaml, new_node_name, new_mac_address)
      node_name_present = current_yaml.keys.include?(new_node_name)
      mac_address_present = current_yaml.values.include?(new_mac_address)

      message = if node_name_present
                  replacing_node_message(current_yaml, new_node_name)
                elsif mac_address_present
                  replacing_mac_address_message(current_yaml, new_mac_address)
                end
      Output.stderr message if message
    end

    def replacing_node_message(current_yaml, new_node_name)
      existing_mac_address = current_yaml[new_node_name]
      "Replacing existing entry for #{new_node_name} " \
        "(existing entry has MAC address #{existing_mac_address})."
    end

    def replacing_mac_address_message(current_yaml, new_mac_address)
      existing_node_name = current_yaml.invert[new_mac_address]
      "Replacing existing entry with MAC address #{new_mac_address} " \
        "(existing entry for node #{existing_node_name})."
    end
  end
end
