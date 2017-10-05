# frozen_string_literal: true

module Metalware
  module Namespaces
    class MetalArray < Array
      def initialize(input_array = nil)
        super()
        push(*input_array)
        define_access_methods
        freeze
      end

      private

      def define_access_methods
        each { |item| define_singleton_method(item.name.to_sym) { item } }
      end
    end
  end
end
