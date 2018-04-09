# frozen_string_literal: true

module Metalware
  module Namespaces
    class AssetArray
      class AssetLoader
        def initialize(path)
          @path = path
        end

        def name
          @name ||= File.basename(path, '.yaml')
        end

        def data
          @data ||= RecursiveOpenStruct.new(Data.load(path))
        end

        private

        attr_reader :path
      end

      include Enumerable

      def initialize
        @asset_loaders = Dir.glob(FilePath.asset('*')).map do |path|
          AssetLoader.new(path).tap do |loader|
            raise_error_if_method_is_defined(loader.name)
            define_singleton_method(loader.name) { loader.data }
          end
        end
      end

      def [](index)
        asset_loaders[index].data
      end

      def each
        asset_loaders.map(&:data).each
      end

      def find_by_name(name)
        asset_loaders.find do |asset|
          asset.name == name
        end.data
      end

      private

      attr_reader :asset_loaders

      def raise_error_if_method_is_defined(method)
        return unless respond_to?(method)
        raise DataError, <<-EOF.strip_heredoc
          Asset can not be called key word: #{method}
        EOF
      end
    end
  end
end

