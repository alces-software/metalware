
require 'recursive-open-struct'

module Metalware
  module HashMergers
    class MetalRecursiveOpenStruct < RecursiveOpenStruct
      def initialize(**hash)
        @alces = hash.delete(:alces)
        super(hash)
      end
    end
  end
end