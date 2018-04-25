# frozen_string_literal: true

module Metalware
  module CommandHelpers
    module HasAssetConcern
      def asset_cache
        @asset_cache ||= Cache::Asset.new
      end

      def ensure_asset_exists
        return if File.exist?(asset_path)
        raise InvalidInput, <<-EOF.squish
          The "#{asset_name}" record does not exist
        EOF
      end
    end
  end
end
