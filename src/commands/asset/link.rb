# frozen_string_literal: true

module Metalware
  module Commands
    module Asset
      class Link < CommandHelpers::BaseCommand
        private

        attr_reader :asset_name, :asset_path, :node

        def setup
          @asset_name = args[1]
          @asset_path = Records::Asset.path(asset_name,
                                            missing_error: true)
          @node = alces.nodes.find_by_name(args[0])
        end

        def run
          Cache::Asset.update do |cache|
            cache.assign_asset_to_node(asset_name, node)
          end
        end
      end
    end
  end
end
