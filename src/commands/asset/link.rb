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
          @asset_path = asset_path_or_error_if_missing(asset_name)
          @node = alces.nodes.find_by_name(args[0])
        end

        def run
          asset_cache.assign_asset_to_node(asset_name, node)
          asset_cache.save
        end
      end
    end
  end
end
