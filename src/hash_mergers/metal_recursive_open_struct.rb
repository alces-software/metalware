
# frozen_string_literal: true

require 'recursive-open-struct'

module Metalware
  module HashMergers
    class MetalRecursiveOpenStruct
      def initialize(table = {}, &templater_block)
        @templater_block = templater_block
        @table = table
      end

      def method_missing(s, *_a, &_b)
        respond_to_missing?(s) ? self[s] : super
      end

      def respond_to_missing?(s, *_a)
        table.key?(s)
      end

      def [](s)
        render_value(table[s])
      end

      def each(&block)
        table.each { |key, value| yield(key, render_value(value)) }
      end

      def to_h
        table
      end

      private

      attr_reader :table, :templater_block

      def render_value(value)
        case value
        when String
          templater_block.call(value)
        when Hash
          MetalRecursiveOpenStruct.new(value, &templater_block)
        else
          value
        end
      end
    end
  end
end
