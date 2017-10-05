
# frozen_string_literal: true

require 'recursive-open-struct'

module Metalware
  module HashMergers
    class MetalRecursiveOpenStruct
      include Enumerable

      def initialize(table = {}, &templater_block)
        @templater_block = templater_block
        @table = table
      end

      def method_missing(s, *_a, &_b)
        if respond_to_missing?(s)
          value = self[s]
          define_singleton_method(s) { value }
          value
        end
      end

      def respond_to_missing?(s, *_a)
        table.key?(s)
      end

      def [](key)
        value = table[key]
        case value
        when String
          templater_block.call(value)
        when Hash
          MetalRecursiveOpenStruct.new(value, &templater_block)
        else
          value
        end
      end

      def each
        table.keys.each { |key| yield(key, send(key)) }
      end

      def to_h
        table
      end

      private

      attr_reader :table, :templater_block
    end
  end
end
