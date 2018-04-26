# frozen_string_literal: true

require 'cache/asset'
require 'fileutils'

module Metalware
  module Commands
    module Asset
      class Delete < CommandHelpers::BaseCommand
        private

        attr_reader :asset_name, :asset_path

        def setup
          @asset_name = args[0]
          @asset_path = Records::Asset.path(asset_name,
                                            missing_error: true)
        end

        def run
          unassign_asset_from_cache
          delete_asset
        end

        def unassign_asset_from_cache
          Cache::Asset.update { |cache| cache.unassign_asset(asset_name) }
        end

        def delete_asset
          FileUtils.rm asset_path
        end
      end
    end
  end
end
