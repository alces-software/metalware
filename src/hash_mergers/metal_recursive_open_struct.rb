
require 'recursive-open-struct'

module Metalware
  module HashMergers
    class MetalRecursiveOpenStruct < RecursiveOpenStruct
      def initialize(**hash)
        @alces = hash.delete(:alces)
        super(hash)
      end

      def method_missing(s, *a, &b)
        render_value(super(s, *a, &b))
      end

      def [](*a)
        render_value(super(*a))
      end

      private

      attr_reader :alces

      def render_value(value)
        if value.is_a? String
          alces.render_erb_template(value)
        else
          value
        end
      end
    end
  end
end