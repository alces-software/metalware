# frozen_string_literal: true

module Metalware
  module Namespaces
    class AssetArray
      include Enumerable

      def initialize
        @files = Dir.glob(FilePath.asset('*'))
      end

      def [](index)
        Data.load(files[index])
      end

      private

      attr_reader :files
    end
  end
end
