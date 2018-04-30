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
  end
end
