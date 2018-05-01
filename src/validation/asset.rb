# frozen_string_literal: true

module Metalware
  module Validation
    class Asset
      def self.valid_file?(path)
        Data.load(path).is_a?(Hash)
      rescue StandardError
        false
      end
    end
  end
end
