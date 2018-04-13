# frozen_string_literal: true

require 'cache/asset'
require 'fileutils'

module Metalware
  module Commands
    module Asset
      class Delete < Metalware::CommandHelpers::BaseCommand
        include CommandHelpers::AssetHelper

        private

        attr_reader :asset_name, :asset_path

        def setup
          @asset_name = args[0]
          @asset_path = FilePath.asset(asset_name)
        end

        def run
          error_if_asset_file_doesnt_exist(asset_path)
          unassign_asset_from_node_if_given(asset_name)
          delete_asset
        end

        def delete_asset
          FileUtils.rm asset_path
        end
      end
    end
  end
end
