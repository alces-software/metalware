# frozen_string_literal: true

module Metalware
  module CommandHelpers
    module EnsureAssetExists
      def post_setup
        super
        return if File.exist?(asset_path)
        raise InvalidInput, <<-EOF.squish
          The "#{asset_name}" record does not exist
        EOF
      end
    end
  end
end
