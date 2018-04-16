module Metalware
  module Commands
    module Asset
      class Unlink < Metalware::CommandHelpers::BaseCommand
        include CommandHelpers::AssetHelper

        private

        attr_reader :asset_name, :asset_path, :node_name

        def setup
          @asset_name = args[0]
          @asset_path = FilePath.asset(asset_name)
          @node_name = args[1]
        end

        def run
          error_if_asset_file_doesnt_exist(asset_path)
          unassign_asset_from_node_if_given(asset_name, node_name)
        end
      end
    end
  end
end
