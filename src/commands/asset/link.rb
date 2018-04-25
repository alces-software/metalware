# frozen_string_literal: true

module Metalware
  module Commands
    module Asset
      class Link < CommandHelpers::BaseCommand
        private

        include CommandHelpers::HasAssetConcern

        attr_reader :asset_name, :asset_path, :node

        def setup
          @asset_name = args[1]
          @asset_path = FilePath.asset(asset_name)
          @node = alces.nodes.find_by_name(args[0])
          ensure_asset_exists
        end

        def run
          asset_cache.assign_asset_to_node(asset_name, node)
          asset_cache.save
        end
      end
    end
  end
end
