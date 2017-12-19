
# frozen_string_literal: true

module Metalware
  module Namespaces
    module Mixins
      module WhiteListHasher
        def to_h
          white_list_hash_methods.tap do |x|
            merge_white_list_recursive_methods(x)
          end
        end

        private

        def white_list_hash_methods(h = {})
          white_list_for_hasher.each_with_object(h) do |method, memo|
            memo[method] = send(method)
          end
        end

        def merge_white_list_recursive_methods(h = {})
          recursive_white_list_for_hasher
            .each_with_object(h) do |method, memo|
            memo[method] = send(method).to_h
          end
        end

        def white_list_for_hasher
          raise NotImplementedError
        end

        def recursive_white_list_for_hasher
          raise NotImplementedError
        end
      end
    end
  end
end
