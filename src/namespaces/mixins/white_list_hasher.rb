
# frozen_string_literal: true

module Metalware
  module Namespaces
    module Mixins
      module WhiteListHasher
        def to_h
          white_list_hash_methods
            .merge(recursive_white_list_hash_methods)
            .merge(recursive_array_white_list_hash_methods)
        end

        private

        def white_list_hash_methods
          method_results_hash(white_list_for_hasher)
        end

        def recursive_white_list_hash_methods
          method_results_hash(recursive_white_list_for_hasher)
            .transform_values(&:to_h)
        end

        def recursive_array_white_list_hash_methods
          method_results_hash(recursive_array_white_list_for_hasher)
            .transform_values { |array| array.map(&:to_h) }
        end

        # Turn an array of method names into a hash of method names to the
        # results of sending those methods to `self`.
        def method_results_hash(method_names)
          method_names.map do |method|
            [method, send(method)]
          end.to_h
        end

        def white_list_for_hasher
          raise NotImplementedError
        end

        def recursive_white_list_for_hasher
          raise NotImplementedError
        end

        def recursive_array_white_list_for_hasher
          raise NotImplementedError
        end
      end
    end
  end
end
