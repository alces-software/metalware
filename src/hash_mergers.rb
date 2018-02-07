
# frozen_string_literal: true

require 'utils/dynamic_require'
require 'hash_mergers/hash_merger'
require 'ostruct'

Metalware::Utils::DynamicRequire.relative('hash_mergers')

module Metalware
  module HashMergers
    class << self
      def merge(config, **inputs, &templater_block)
        OpenStruct.new(config: Config.new.merge(**inputs, &templater_block),
                       answer: Answer.new.merge(**inputs, &templater_block))
      end
    end
  end
end
