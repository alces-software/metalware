
# frozen_string_literal: true

require 'exceptions'
require 'templating/iterable_recursive_open_struct'

module Metalware
  module Templating
    class MissingParameterWrapper
      include Blank
      delegate :to_json, to: :@wrapped_obj

      def initialize(wrapped_obj, raise_on_missing: false, callstack: [])
        @raise_on_missing = raise_on_missing
        @missing_tags = []
        @callstack = callstack
        @wrapped_obj = if wrapped_obj.is_a?(Hash)
                         IterableRecursiveOpenStruct.new(wrapped_obj)
                       else
                         wrapped_obj
                       end
      end

      def inspect
        @wrapped_obj
      end

      def wrapper_binding
        binding
      end

      def method_missing(method, *args, &block)
        new_callstack = updated_callstack(method, *args, &block)
        value = @wrapped_obj.send(method, *args, &block)
        if value.nil? && !@missing_tags.include?(method)
          msg = "Unset template parameter: #{callstack_string(new_callstack)}"
          raise MissingParameterError, msg if @raise_on_missing
          @missing_tags.push(method)
          MetalLog.warn msg
        end
        if /to_/.match?(method) || (method == :send && /to_/.match(args[0]))
          return value
        end
        case value
        when true, false, nil
          value
        else
          MissingParameterWrapper.new(value, callstack: new_callstack)
        end
      end

      private

      def updated_callstack(method, *args, &block)
        str = method.to_s
        str << "(#{args.join(',')})" unless args.empty?
        str << '{ ... }' if block
        @callstack + [str]
      end

      def callstack_string(callstack)
        callstack.join('.')
      end
    end
  end
end
