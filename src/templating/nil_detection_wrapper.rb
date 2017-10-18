
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

      def initialize(object, call_stack = '')
        @object = object
        @call_stack = call_stack
      end

      def alces_wrapper_binding
        binding
      end

      def respond_to_missing?(*_a)
        true # Respond to everything as it will be passed to wrapped obj
      end

      def method_missing(s, *a, &b)
        # Should never super. Only included as method_missing should always
        # have a failback on super
        super unless respond_to_missing?(s)
        value = object.send(s, *a, &b)
        if s == :to_s || s == :to_str
          value
        else
          next_call_stack = build_call_stack_str(s, *a, &b)
          parse_value(value, next_call_stack)
        end
      end

      private

      attr_reader :object, :call_stack

      def build_call_stack_str(s, *a, &b)
        stop = call_stack.empty? ? '' : '.'
        call_stack + stop + build_call_stack_helper(s, *a, &b)
      end

      def build_call_stack_helper(s, *_a, &_b)
        s.to_s
      end

      def parse_value(value, next_call_stack)
        if value.nil?
          nil_detected(next_call_stack)
          nil
        else
          NilDetectionWrapper.new(value, next_call_stack)
        end
      end

      def nil_detected(next_call_stack)
        MetalLog.warn next_call_stack
      end
    end
  end
end
