
require 'exceptions'
require 'iterable_recursive_open_struct'


module Metalware
  class MissingParameterWrapper
    def initialize(wrapped_obj, raise_on_missing: false)
      @raise_on_missing = raise_on_missing
      @missing_tags = []
      @wrapped_obj = if wrapped_obj.is_a?(Hash)
                       IterableRecursiveOpenStruct.new(wrapped_obj)
                     else
                       wrapped_obj
                     end
    end

    def method_missing(s, *a, &b)
      value = @wrapped_obj.send(s)
      if value.nil? && ! @missing_tags.include?(s)
        msg = "Unset template parameter: #{s}"
        # TODO: This code causes alces.answer.<missing-parameter> to throw an error
        # This is the correct behavior but it is breaking the tests
        # The offending tests need to be switched over to using FakeFS, then this
        # code can be uncommented.
        #if @fatal
        #  raise MissingParameter, msg
        #else
        @missing_tags.push s
        MetalLog.warn msg
        #end
      end
      value
    end

    def inspect
      @wrapped_obj
    end

    def [](a)
      # ERB expects to be able to index in to the binding passed; this should
      # function the same as a method call.
      send(a)
    end

    def method_missing(s, *a, &b)
      value = @wrapped_obj.send(s)
      if value.nil? && ! @missing_tags.include?(s)
        msg = "Unset template parameter: #{s}"
        raise(MissingParameter, msg) if @raise_on_missing
        @missing_tags.push(s)
        MetalLog.warn msg
      end
      value
    end
  end
end
