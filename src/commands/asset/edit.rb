# frozen_string_literal: true

module Metalware
  module Commands
    module Asset
      class Edit < CommandHelpers::AssetEditor
        private

        attr_reader :asset_name, :asset_path

        alias source asset_path
        alias destination source

        def setup
          @asset_name = args[0]
          @asset_path = Records::Asset.path(asset_name,
                                            missing_error: true)
          unpack_node_from_options
        end
      end
    end
  end
end
