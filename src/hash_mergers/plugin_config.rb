
# frozen_string_literal: true

require 'hash_mergers/hash_merger'

module Metalware
  module HashMergers
    class PluginConfig < HashMerger
      def initialize(plugin:)
        @plugin = plugin
        super
      end

      private

      attr_reader :plugin

      def load_yaml(section, section_name)
        # XXX This is the same as `HashMergers::Config`, just using `plugin`
        # rather than `file_path`.
        args = [section_name].compact
        config_file = plugin.send("#{section}_config", *args)
        Data.load(config_file)
      end
    end
  end
end
