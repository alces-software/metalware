
# frozen_string_literal: true

require 'hash_mergers/hash_merger'

module Metalware
  module HashMergers
    class Answer < HashMerger
      private

      def load_yaml(section, section_name = nil)
        input = (section_name ? [section_name] : [])
        loader.section_answers(section, *input)
      end
    end
  end
end
