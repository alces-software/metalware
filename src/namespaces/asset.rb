# frozen_string_literal: true

module Metalware
  module Namespaces
    class Asset < HashMergers::MetalRecursiveOpenStruct
      def self.new(table = {})
        super(table) { |s| s }
      end
    end
  end
end
