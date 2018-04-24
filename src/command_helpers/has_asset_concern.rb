# frozen_string_literal: true

module Metalware
  module CommandHelpers
    module HasAssetConcern
      def asset_cache
        @asset_cache ||= Cache::Asset.new
      end

      def asset_path_or_error_if_missing(name)
        path = Records::Path.asset(name)
        return path if path
        raise InvalidInput, <<-EOF.squish
          The "#{name}" record does not exist
        EOF
      end
    end
  end
end
