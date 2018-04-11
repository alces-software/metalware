# frozen_string_literal: true

require 'utils/editor'

module Metalware
  module Commands
    module Asset
      class Edit < Metalware::CommandHelpers::BaseCommand
        private

        attr_reader :asset_name, :asset_path

        def setup
          @asset_name = args[0]
          @asset_path = FilePath.asset(asset_name)
        end

        def run
          error_if_asset_doesnt_exist
          Utils::Editor.open_copy(asset_path, asset_path)
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

