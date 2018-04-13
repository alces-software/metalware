# frozen_string_literal: true

require 'cache/asset'
require 'fileutils'

module Metalware
  module Commands
    module Asset
      class Delete < Metalware::CommandHelpers::BaseCommand
        include CommandHelpers::AssetHelper

        private

        attr_reader :name, :path, :cache

        def setup
          @name = args[0]
          @path = FilePath.asset(name)
          @cache = Metalware::Cache::Asset.new
        end

        def run
          error_if_asset_file_doesnt_exist(name, path)
          cache.unassign_asset(name)
          cache.save
          delete_asset
        end

        def delete_asset
          FileUtils.rm path
        end
      end
    end
  end
end
