
# frozen_string_literal: true

require 'namespaces/hash_merger_namespace'

# A Plugin namespace contains the values configured for a particular plugin for
# a particular node.

module Metalware
  module Namespaces
    class Plugin < HashMergerNamespace
      attr_reader :node_namespace, :plugin

      delegate :name, to: :plugin

      # These methods are defined in HashMergerNamespace, but are not
      # meaningful for this namespace.
      undef :answer, :render_erb_template

      def initialize(plugin, node:)
        @node_namespace = node
        @plugin = plugin
        alces = node.send(:alces)
        super(alces, plugin.name)
      end

      def config
        @config ||= run_hash_merger(plugin_config_hash_merger)
      end

      def files
        @files ||= alces.build_files_retriever.retrieve_for_plugin(self)
      end

      private

      def plugin_config_hash_merger
        HashMergers::PluginConfig.new(
          metal_config: alces.send(:metal_config),
          plugin: plugin
        )
      end

      def hash_merger_input
        # The plugin config should be merged in the same order as specified in
        # the containing node namespace.
        node_namespace.send(:hash_merger_input)
      end

      def additional_dynamic_namespace
        { node: node_namespace }
      end
    end
  end
end
