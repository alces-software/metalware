
# frozen_string_literal: true

require 'utils/dynamic_require'
require 'hash_mergers/metal_recursive_open_struct'
require 'hash_mergers/hash_merger'
require 'ostruct'

Metalware::Utils::DynamicRequire.relative('hash_mergers')

module Metalware
  module HashMergers
    class << self
      def merge(config, **inputs)
        OpenStruct.new({
          config: Config.new(config, **inputs),
          answer: Answer.new(config, **inputs),
        })
      end
    end
  end
end

