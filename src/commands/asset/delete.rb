# frozen_string_literal: true

require 'cache/asset'
require 'fileutils'

module Metalware
  module Commands
    module Asset
      class Delete < Metalware::CommandHelpers::BaseCommand
        private

        attr_reader :name, :path, :cache

        def setup
          @name = args[0]
          @path = FilePath.asset(name)
          @cache = Metalware::Cache::Asset.new
        end

        def run
          error_if_asset_doesnt_exist
          cache.unassign_asset(name)
          cache.save
          delete_asset
        end

        def error_if_asset_doesnt_exist
          return if File.exist?(path)
          raise InvalidInput, <<-EOF.squish
            The "#{name}" asset does not yet exist to delete.
          EOF
        end

        def delete_asset
          FileUtils.rm path
        end
      end
    end
  end
end
