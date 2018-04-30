# frozen_string_literal: true

require 'records/layout'
require 'records/asset'

module Metalware
  class AssetBuilder
    attr_reader :queue

    def initialize
      @queue ||= []
    end
  end
end
