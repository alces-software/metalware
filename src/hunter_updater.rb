
require 'yaml'

require 'output'


module Metalware
  class HunterUpdater
    def initialize(hunter_file)
      @hunter_file = hunter_file
    end

    def add(node_name, mac_address)
      node_name = node_name.to_sym

      current_yaml = load_current_yaml
      remove_colliding_entries!(current_yaml, node_name, mac_address)

      new_yaml = YAML.dump(current_yaml.merge({
        node_name.to_sym => mac_address
      }))
      File.write(@hunter_file, new_yaml)
    end

    private

    def load_current_yaml
      if File.exist? @hunter_file
        YAML.load_file(@hunter_file) || {}
      else
        {}
      end
    end

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
