
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
          next_call_stack = build_call_stack_str(s, *a, &b)
          parse_value(object.send(s, *a, &b), next_call_stack)
        else
          super
        end
      end

      private

      attr_reader :object, :call_stack

      def build_call_stack_str(s, *_a, &_b)
        s.to_s
      end

      def parse_value(value, next_call_stack)
        if value.nil?
          nil_detected(next_call_stack)
          nil
        else
          NilDetectionWrapper.new(value)
        end
      end

      def nil_detected(next_call_stack)
        MetalLog.warn next_call_stack
      end
    end
  end
end
