# frozen_string_literal: true

module Metalware
  module Namespaces
    class AssetArray
      class AssetLoader
        def initialize(alces, path)
          @alces = alces
          @path = path
        end

        def name
          @name ||= File.basename(path, '.yaml')
        end

        def data
          @data ||= begin
            data_class = Constants::HASH_MERGER_DATA_STRUCTURE
            data_class.new(load_file) do |str|
              if str[0] == ':'
                other_asset_name = str[1..-1]
                alces.assets.find_by_name(other_asset_name)
              else
                str
              end
            end
          end
        end

        private

        attr_reader :alces, :path

        def load_file
          Data.load(path).merge(metadata: { name: name })
        end
      end

      include Enumerable

      def initialize(alces)
        @alces = alces
        @asset_loaders = Dir.glob(FilePath.asset('*')).map do |path|
          AssetLoader.new(alces, path).tap do |loader|
            raise_error_if_method_is_defined(loader.name)
            define_singleton_method(loader.name) { loader.data }
          end
        end
      end

      def [](index)
        asset_loaders[index].data
      end

      def each(&b)
        enum = asset_loaders.map(&:data).each
        block_given? ? enum.each(&b) : enum
      end

      def find_by_name(name)
        asset_loaders.find do |asset|
          asset.name == name
        end&.data
      end

      private

      attr_reader :alces, :asset_loaders

      def raise_error_if_method_is_defined(method)
        return unless respond_to?(method)
        raise DataError, <<-EOF.strip_heredoc
          Asset can not be called key word: #{method}
        EOF
      end
    end
  end
end
