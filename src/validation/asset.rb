# frozen_string_literal: true

module Metalware
  module Validation
    class Asset
      def self.valid_file?(path)
        data = Data.load(path)
        data.is_a?(Hash) ? data : false
      rescue StandardError
        false
      end
    end
  end
end
