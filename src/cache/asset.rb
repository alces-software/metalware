# frozen_string_literal: true

require 'file_path'
require 'data'

module Metalware
  module Cache
    class Asset
      def initialize
        data
      end

      def data
        @assets ||= Data.load(FilePath.asset_cache)
      end
      
      def save
        Data.dump(FilePath.asset_cache, data) 
      end

      def assign_asset_to_node(asset_name, node)
        @assets["node"][node.name] = asset_name  
      end

      def asset_for_node(node)
        @assets["node"][node.name]
      end
    end
  end
end
