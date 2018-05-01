# frozen_string_literal: true

require 'utils/editor'

module Metalware
  module Commands
    module Asset
      class Add < CommandHelpers::AssetEditor
        private

        attr_reader :type_name, :type_path

        alias source type_path

        def setup
          @type_name = args[0]
          @type_path = FilePath.asset_type(type_name)
          @asset_name = args[1]
          error_if_type_is_missing
          Records::Asset.error_if_unavailable(asset_name)
          FileUtils.mkdir_p File.dirname(destination)
        end

        def edit_first_asset
          asset_builder.push_asset(asset_name, type_name)
          asset_builder.pop_asset.edit_and_save
        end

        def destination
          FilePath.asset(type_name.pluralize, asset_name)
        end

        def error_if_type_is_missing
          return if File.exist?(type_path)
          raise InvalidInput, <<-EOF.squish
            Cannot find asset type: "#{type_name}"
          EOF
        end
      end
    end
  end
end
