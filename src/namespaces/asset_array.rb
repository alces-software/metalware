# frozen_string_literal: true

require 'records/asset'

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

        def type
          @type ||= File.basename(File.dirname(path)).singularize
        end

        def data
          @data ||= begin
            data_class = Constants::HASH_MERGER_DATA_STRUCTURE
            data_class.new(load_file) do |str|
              if str[0] == '^'
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
          Data.load(path).merge(metadata: { name: name, type: type })
        end
      end

      include Enumerable

      def initialize(alces, loaders_input: nil)
        @alces = alces
        @asset_loaders = loaders_input || create_asset_loaders
        asset_loaders.each { |l| define_asset_method_from_loader(l) }
        define_type_methods unless loaders_input
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

      def define_asset_method_from_loader(loader)
        raise_error_if_method_is_defined(loader.name)
        define_singleton_method(loader.name) { loader.data }
      end

      def create_asset_loaders
        Records::Asset.paths.map do |path|
          AssetLoader.new(alces, path)
        end
      end

      def define_type_methods
        Records::Asset::TYPES.map(&:pluralize).each do |type_plural|
          type_variable = :"@#{type_plural}"
          loaders = asset_loaders.select do |loader|
            loader.type == type_plural.singularize
          end
          sub_array = self.class.new(alces, loaders_input: loaders)
          instance_variable_set(type_variable, sub_array)
          define_singleton_method(type_plural) do
            instance_variable_get(type_variable)
          end
        end
      end
    end
  end
end
