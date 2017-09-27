
# frozen_string_literal: true

require 'hash_mergers/hash_merger'

module Metalware
  module HashMergers
    class Config < HashMerger
      private

      def load_yaml(section, section_name = nil)
        input = (section_name ? [section_name] : [])
        Data.load(file_path.send("#{section}_config", *input))
      end
    end
  end
end
