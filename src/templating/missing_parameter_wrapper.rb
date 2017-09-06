
# frozen_string_literal: true

require 'exceptions'
require 'templating/iterable_recursive_open_struct'

module Metalware
  module Templating
    class MissingParameterWrapper
      include Blank
      delegate :to_json, to: :@wrapped_obj

      def initialize(wrapped_obj, raise_on_missing: false)
        @raise_on_missing = raise_on_missing
        @missing_tags = []
        @wrapped_obj = if wrapped_obj.is_a?(Hash)
                         IterableRecursiveOpenStruct.new(wrapped_obj)
                       else
                         wrapped_obj
                       end
      end

      def inspect
        @wrapped_obj
      end

      def [](a)
        # ERB expects to be able to index in to the binding passed; this should
        # function the same as a method call.
        send(a)
      end

      def wrapper_binding
        binding
      end

      def method_missing(method, *args, &block)
        value = @wrapped_obj.send(method, *args, &block)
        if value.nil? && !@missing_tags.include?(method)
          msg = "Unset template parameter: #{method}"
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
          MissingParameterWrapper.new(value)
        end
      end
    end
  end
end
