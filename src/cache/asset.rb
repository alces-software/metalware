# frozen_string_literal: true

require 'file_path'
require 'data'

module Metalware
  module Cache
    class Asset
      def data
        @data ||= begin
          raw_load = Data.load(FilePath.asset_cache)
          raw_load.empty? ? blank_cache : raw_load
        end
      end

      def save
        Data.dump(FilePath.asset_cache, data)
      end

      def assign_asset_to_node(asset_name, node)
        data[:node][node.name.to_sym] = asset_name
      end

      def asset_for_node(node)
        data[:node][node.name.to_sym]
      end

      def unassign_asset(asset_name, node_name = nil)
        data[:node].delete_if do |node, asset|
          next unless asset == asset_name
          check_node_name_if_given(node, node_name)
        end
      end

      private

      def check_node_name_if_given(node, node_name)
        node_name ? (node == node_name.to_sym) : true
      end

      def blank_cache
        { node: {} }
      end
    end
  end
end
