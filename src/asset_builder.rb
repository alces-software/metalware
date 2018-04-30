# frozen_string_literal: true

require 'records/layout'
require 'records/asset'

module Metalware
  class AssetBuilder
    attr_reader :stack

    def initialize
      @stack ||= []
    end

    def push_asset(name, layout_or_type)
      if (details = source_file_details(layout_or_type))
        stack.push(Asset.new(name, details.path, details.type))
      else
        MetalLog.warn <<-EOF.squish
          Failed to add asset: "#{name}". Could not find layout:
          "#{layout_or_type}"
        EOF
      end
    end

    def pop_asset
      asset = stack.pop
      if asset.nil?
        nil
      elsif Records::Asset.available?(asset.name)
        asset
      else
        pop_asset
      end
    end

    private

    def source_file_details(layout_or_type)
      if Records::Asset::TYPES.include?(layout_or_type)
        OpenStruct.new(
          type: layout_or_type,
          path: FilePath.asset_type(layout_or_type)
        )
      elsif (path = Records::Layout.path(layout_or_type))
        OpenStruct.new(
          type: Records::Layout.type_from_path(path),
          path: path
        )
      end
    end

    Asset = Struct.new(:name, :source_path, :type) do
      def save
        raise_if_source_invalid(source_path)
        asset_path = FilePath.asset(type.pluralize, name)
        Utils.copy_via_temp_file(source_path, asset_path) {}
      end

      private

      def raise_if_source_invalid(source_path)
        return if Validation::Asset.valid_file?(source_path)
        raise InvalidInput, <<-EOF
          Failed to add asset: "#{name}". Please check the layout is valid:
          "#{source_path}"
        EOF
      end
    end
  end
end
