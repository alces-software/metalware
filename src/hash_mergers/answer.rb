
# frozen_string_literal: true

require 'hash_mergers/hash_merger'

module Metalware
  module HashMergers
    class Answer < HashMerger
      private

      def hash_array(*a)
        super.unshift(domain_answers)
      end

      def domain_answers
        loader.flattened_configure_section(:domain)
              .reject { |_k, value| value.default.nil? }
              .map { |key, value| [key, value.default] }
              .to_h
      end

      def load_yaml(section, section_name)
        loader.section_answers(section, section_name)
      end
    end
  end
end
