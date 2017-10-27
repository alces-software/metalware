
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
          x.push(default_hash(:node)) if node
        end
      end

      def default_hash(section)
        configure_data[section].each_with_object({}) do |(key, value), memo|
          memo[key] = value[:default] if value.key? :default
        end
      end

      def load_yaml(section, section_name = nil)
        input = (section_name ? [section_name] : [])
        loader.section_answers(section, *input)
      end

      def configure_data
        @configure_data ||= loader.configure_data
      end
    end
  end
end
