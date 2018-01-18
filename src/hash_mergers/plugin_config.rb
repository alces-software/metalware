
# frozen_string_literal: true

require 'hash_mergers/hash_merger'

module Metalware
  module HashMergers
    class PluginConfig < HashMerger
      def initialize(plugin, metalware_config)
        @plugin = plugin
        super(metalware_config)
      end

      private

      attr_reader :plugin

      def load_yaml(section, section_name)
        args = [section_name].compact
        config_file = plugin.send("#{section}_config", *args)
        Data.load(config_file)
      end
    end
  end
end
