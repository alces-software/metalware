
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

      private

      attr_reader :alces

      def render_value(value)
        value.is_a?(String) ? @templater_block.call(value) : value
      end
    end
  end
end
