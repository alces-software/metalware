# frozen_string_literal: true

module Metalware
  module CommandHelpers
    module AssetCache
      private

      def asset_cache
        @asset_cache ||= Cache::Asset.new
      end
    end
  end
end
