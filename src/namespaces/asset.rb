# frozen_string_literal: true

module Metalware
  module Namespaces
    class Asset < HashMergers::MetalRecursiveOpenStruct
      def self.new(table = {})
        super
      end
    end
  end
end
