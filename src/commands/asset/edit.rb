# frozen_string_literal: true

module Metalware
  module Commands
    module Asset
      class Edit < Metalware::CommandHelpers::BaseCommand
        include CommandHelpers::AssetHelper

        private

        attr_reader :asset_name, :asset_path

        def setup
          @asset_name = args[0]
          @asset_path = FilePath.asset(asset_name)
          unpack_node_from_options
        end

        def run
          error_if_asset_file_doesnt_exist(asset_path)
          edit_asset_file(asset_path)
          assign_asset_to_node_if_given(asset_name)
        end
      end
    end
  end
end
