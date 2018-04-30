# frozen_string_literal: true

require 'records/layout'
require 'records/asset'

module Metalware
  class AssetBuilder
    attr_reader :stack

    delegate :empty?, to: :stack

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
      stack.pop
    end

    private

    Asset = Struct.new(:name, :source_path, :type)

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
  end
end
