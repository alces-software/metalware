# frozen_string_literal: true

require 'file_path'
require 'data'

module Metalware
  module Cache
    class Asset
      def data
        @assets ||= begin
          Data.load(FilePath.asset_cache).tap do |a|
            a.merge! blank_cache if a.empty?
          end
        end
      end
      
      def save
        Data.dump(FilePath.asset_cache, data) 
      end

      def assign_asset_to_node(asset_name, node)
        data[:node][node.name] = asset_name  
      end

      def asset_for_node(node)
        data[:node][node.name]
      end

      private

      def blank_cache
        { node: {} }  
      end
    end
  end
end
