# frozen_string_literal: true

module Metalware
  module Commands
    module Asset
      class Edit < CommandHelpers::AssetEditor
        private

        def setup
          @asset_name = args[0]
        end

        def edit_first_asset
          asset_builder.edit_asset(asset_name)
        end
      end
    end
  end
end
