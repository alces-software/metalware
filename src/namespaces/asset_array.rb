# frozen_string_literal: true

module Metalware
  module Namespaces
    class AssetArray
      class AssetLoader
        def initialize(path)
          @path = path
        end

        def data
          @data ||= Data.load(path)
        end

        private

        attr_reader :path
      end

      include Enumerable

      def initialize
        @asset_loaders = Dir.glob(FilePath.asset('*')).map do |path|
          AssetLoader.new(path)
        end
      end

      def [](index)
        asset_loaders[index].data
      end

      private

      attr_reader :asset_loaders
    end
  end
end
