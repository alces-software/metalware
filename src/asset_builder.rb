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
      queue.push(Asset.new(name, layout))
    end

    private

    Asset = Struct.new(:name, :layout)

    def layout_path_with_types(base_name)
      if Records::Asset::TYPES.include?(base_name)
        FilePath.asset_type(base_name)
      elsif (layout_path = Records::Layout.path(base_name))
        layout_path
      else
        nil
      end
    end
  end
end
