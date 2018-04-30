# frozen_string_literal: true

require 'records/layout'
require 'records/asset'

module Metalware
  class AssetBuilder
    attr_reader :queue

    def initialize
      @queue ||= []
    end

    def push_asset(name, layout)
      if (path = layout_or_type_path(layout))
        queue.push(Asset.new(name, path))
      else
        MetalLog.warn <<-EOF.squish
          Failed to add "#{name}". Could not find layout: "#{layout}"
        EOF
      end
    end

    private

    Asset = Struct.new(:name, :source_path)

    def layout_or_type_path(layout_or_type)
      if Records::Asset::TYPES.include?(layout_or_type)
        FilePath.asset_type(layout_or_type)
      else
        Records::Layout.path(layout_or_type)
      end
    end
  end
end
