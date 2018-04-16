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

      def unassign_asset(asset_name, *node_name)
        data.each_value do |value|
          value.delete_if do |node, asset|
            if node_name.empty?
              asset == asset_name
            else
              node == node_name[0].to_sym && asset == asset_name
            end
          end
        end
      end

      private

      def blank_cache
        { node: {} }
      end
    end
  end
end
