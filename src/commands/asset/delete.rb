# frozen_string_literal: true

require 'cache/asset'
require 'fileutils'

module Metalware
  module Commands
    module Asset
      class Delete < CommandHelpers::BaseCommand
        private

        include CommandHelpers::EnsureAssetExists

        attr_reader :asset_name, :asset_path, :cache

        def setup
          @asset_name = args[0]
          @asset_path = FilePath.asset(asset_name)
          @cache = Cache::Asset.new
        end

        def run
          unassign_asset_from_cache
          delete_asset
        end

        def unassign_asset_from_cache
          cache.unassign_asset(asset_name)
          cache.save
        end

        def delete_asset
          FileUtils.rm asset_path
        end
      end
    end
  end
end
