# frozen_string_literal: true

module Metalware
  module Commands
    module Asset
      class Edit < Metalware::CommandHelpers::BaseCommand
        include CommandHelpers::AssetHelper

        private

        attr_reader :asset_name, :asset_path

        def setup
          @asset_name = args[0]
          @asset_path = FilePath.asset(asset_name)
          unpack_node_from_options
        end

        def run
          error_if_asset_doesnt_exist
          edit_asset_file(asset_path)
          assign_asset_to_node_if_given(asset_name)
        end

        def error_if_asset_doesnt_exist
          return if File.exist?(asset_path)
          raise InvalidInput, <<-EOF.squish
            The "#{asset_name}" asset does not yet exist. Use 'metal
            asset add' to create the asset
          EOF
        end
      end
    end
  end
end
