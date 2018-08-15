
# frozen_string_literal: true

require 'namespaces/hash_merger_namespace'

# A Plugin namespace contains the values configured for a particular plugin for
# a particular node.

module Metalware
  module Namespaces
    class Plugin < HashMergerNamespace
      attr_reader :node_namespace, :plugin

      delegate :name, to: :plugin

      # `answer` is defined in HashMergerNamespace, but is not meaningful for
      # this namespace (plugin answers are included within those for the
      # containing node namespace as a whole).
      undef :answer

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
        @files ||= begin
                     data = alces
                            .build_files_retriever.retrieve(self)
                     node_namespace.finalize_build_files(data)
                   end
      end

      private

      def plugin_config_hash_merger
        HashMergers::PluginConfig.new(plugin: plugin)
      end

      def hash_merger_input
        # The plugin config should be merged in the same order as specified in
        # the containing node namespace.
        node_namespace.send(:hash_merger_input)
      end

      def additional_dynamic_namespace
        { node: node_namespace }
      end

      def recursive_white_list_for_hasher
        [:config, :files]
      end
    end
  end
end
