# frozen_string_literal: true

require 'utils/editor'

module Metalware
  module Commands
    module Asset
      class Add < CommandHelpers::AssetEditor
        private

        attr_reader :type_name

        def setup
          @type_name = args[0]
          @asset_name = args[1]
          Records::Asset.error_if_unavailable(asset_name)
        end

        def edit_first_asset
          asset_builder.push_asset(asset_name, type_name)
          asset_builder.pop_asset&.edit_and_save
        end
      end
    end
  end
end
