# frozen_string_literal: true

module Metalware
  module Commands
    module Asset
      class Edit < CommandHelpers::AssetEditor
        private

        attr_reader :asset_path

        alias source asset_path
        alias destination source

        def setup
          @asset_name = args[0]
          @asset_path = Records::Asset.path(asset_name,
                                            missing_error: true)
        end

        def edit_first_asset
          copy_and_edit_record_file
        end
      end
    end
  end
end
