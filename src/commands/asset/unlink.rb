# frozen_string_literal: true

module Metalware
  module Commands
    module Asset
      class Unlink < CommandHelpers::BaseCommand
        private

        include CommandHelpers::AssetCache

        attr_reader :node_name

        def setup
          @node_name = args[0]
        end

        def run
          unassign_node_from_cache
        end

        def unassign_node_from_cache
          asset_cache.unassign_node(node_name)
          asset_cache.save
        end
      end
    end
  end
end
