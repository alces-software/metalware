
# frozen_string_literal: true

require 'recursive-open-struct'

module Metalware
  module HashMergers
    class MetalRecursiveOpenStruct < RecursiveOpenStruct
      def initialize(*args, **hash, &templater_block)
        @templater_block = templater_block
        super(*args, **hash)
      end

      def method_missing(s, *a, &b)
        render_value(super(s, *a, &b))
      end

      def respond_to_missing?
        super
      end

      def [](*a)
        render_value(super(*a))
      end

      def each_pair(&block)
        super { |key, value| yield(key, render_value(value)) }
      end
      alias_method :each, :each_pair

      private

      attr_reader :alces

      def render_value(value)
        case value
        when String
          @templater_block.call(value)
        when Hash
          MetalRecursiveOpenStruct.new(value, &templater_block)
        else
          value
        end
      end
    end
  end
end
