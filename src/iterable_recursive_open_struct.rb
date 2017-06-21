require 'recursive-open-struct'

module Metalware
  class IterableRecursiveOpenStruct < RecursiveOpenStruct
    def each(&block)
      convert_hash_values_to_own_class.each(&block)
    end

    def each=(*args)
      raise IterableRecursiveOpenStructPropertyError,
        "Cannot set property 'each', reserved to use for iteration"
    end

    private

    def convert_hash_values_to_own_class
      to_h.map do |k, v|
        case v
        when Hash
          [k, IterableRecursiveOpenStruct.new(v)]
        else
          [k, v]
        end
      end.to_h
    end
  end
end
