
# frozen_string_literal: true

require 'active_support/core_ext/module/delegation'

module Metalware
  module HashMergers
    class MetalRecursiveOpenStruct
      include Enumerable

      def initialize(table = {}, &input_block)
        @convert_string_block = input_block || proc { |s| s }
        @table = table
      end

      delegate :key?, to: :table

      def method_missing(s, *_a, &_b)
        return nil unless respond_to_missing?(s)
        value = self[s]
        define_singleton_method(s) { value }
        value
      end

      def respond_to_missing?(s, *_a)
        table.key?(s)
      end

      def [](key)
        value = table[key]
        convert_value(value)
      end

      def each
        table.each_key { |key| yield(key, send(key)) }
      end

      def each_value
        each { |_s, value| yield value } # rubocop:disable Performance/HashEachMethods
      end

      def to_h
        table
      end

      def to_json(*_a)
        to_h.to_json
      end

      private

      attr_reader :table, :convert_string_block

      def convert_value(value)
        case value
        when String
          convert_string_block.call(value)
        when Hash
          self.class.new(value, &convert_string_block)
        when Array
          value.map { |arg| convert_value(arg) }
        else
          value
        end
      end
    end
  end
end
