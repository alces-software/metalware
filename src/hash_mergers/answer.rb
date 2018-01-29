
# frozen_string_literal: true

require 'hash_mergers/hash_merger'

module Metalware
  module HashMergers
    class Answer < HashMerger
      private

      def hash_array(*a)
        default_array(*a).concat super
      end

      def default_array(groups:, node:)
        [default_hash(:domain)].tap do |x|
          x.push(default_hash(:group)) if groups
          if node == 'local'
            x.push(default_hash(:local))
          elsif node
            x.push(default_hash(:node))
          end
        end
      end

      def default_hash(section)
        section_default(section).each_with_object({}) do |(key, value), memo|
          memo[key] = value.default unless value.default.nil?
        end
      end

      def load_yaml(section, section_name)
        loader.section_answers(section, section_name)
      end

      def section_default(section)
        loader.flattened_configure_section(section)
      end
    end
  end
end
