
# frozen_string_literal: true

module Metalware
  module Templating
    class NilDetectionWrapper
      class << self
        def wrap(object)
          wrapper = new(object)
          wrapper.alces_wrapper_binding
        end
      end

      include Blank

      def initialize(object, call_stack = nil)
        @object = object
        @call_stack = call_stack
      end

      def alces_wrapper_binding
        binding
      end

      def respond_to_missing?(s, *_a)
        object.respond_to?(s)
      end

      def method_missing(s, *a, &b)
        if respond_to_missing?(s)
          parse_value(object.send(s, *a, &b))
        else
          super
        end
      end

      private

      attr_reader :object, :call_stack

      def parse_value(value)
        if value.nil?
          MetalLog.warn 'Nil detected'
          nil
        else
          value
        end
      end
    end
  end
end
