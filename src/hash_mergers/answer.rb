
# frozen_string_literal: true

require 'hash_mergers/hash_merger'

module Metalware
  module HashMergers
    class Answer < HashMerger
      private

      def load_yaml(section, section_name = nil)
        input = (section_name ? [section_name] : [])
        defaults = configure_data[section].map do |key, value|
          [key, value[:default]]
        end.to_h
        answers = loader.section_answers(section, *input)
        defaults.merge(answers)
      end

      def configure_data
        @configure_data ||= loader.configure_data
      end
    end
  end
end
