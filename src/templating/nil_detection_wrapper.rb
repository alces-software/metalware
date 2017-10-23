
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

      START_CALL_STACK_MSG = 'The following returned nil: '

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
        if [:to_s, :to_str].include?(s)
          value
        else
          next_call_stack = build_call_stack_str(s, *a, &b)
          parse_value(value, next_call_stack)
        end
      end

      private

      attr_reader :object, :call_stack

      def build_call_stack_str(s, *a, &b)
        stop = call_stack.empty? ? START_CALL_STACK_MSG : '.'
        call_stack + stop + build_call_stack_helper(s.to_s, *a, &b)
      end

      def build_call_stack_helper(s, *a, &b)
        if s == '[]'
          key = a.shift
          key = (key.is_a?(Symbol) ? ":#{key}" : "'#{key}'")
          s = "[#{key}]".dup
        end
        return s if a.empty? && b.nil?
        s << '('
        s << a.join(', ')
        s << ', ' if b && !a.empty?
        s << '&block' if b
        s << ')'
      end

      def parse_value(value, next_call_stack)
        if value.nil?
          MetalLog.warn next_call_stack
          nil
        else
          NilDetectionWrapper.new(value, next_call_stack)
        end
      end
    end
  end
end
