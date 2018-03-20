
# frozen_string_literal: true

require 'hash_mergers/hash_merger'

module Metalware
  module HashMergers
    class Answer < HashMerger
      def initialize(alces)
        @alces = alces
        super
      end

      private

      attr_reader :alces

      def defaults
        alces.questions.root_defaults
      end

      def load_yaml(section, section_name)
        loader.section_answers(section, section_name)
      end
    end
  end
end
