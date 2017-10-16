
# frozen_string_literal: true

require 'active_support/core_ext/module/delegation'

module Metalware
  module HashMergers
    class MetalRecursiveOpenStruct
      include Enumerable

      def initialize(table = {}, &templater_block)
        @templater_block = templater_block
        @table = table
      end

      delegate :key?, to: :table

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
        convert_value(value)
      end

      def each
        table.keys.each { |key| yield(key, send(key)) }
      end

      def to_h
        table
      end

      private

      attr_reader :table, :templater_block

      def convert_value(value)
        case value
        when String
          templater_block.call(value)
        when Hash
          MetalRecursiveOpenStruct.new(value, &templater_block)
        when Array
          value.map { |arg| convert_value(arg) }
        else
          value
        end
      end
    end
  end
end
