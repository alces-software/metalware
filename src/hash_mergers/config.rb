
# frozen_string_literal: true

require 'hash_mergers/hash_merger'

module Metalware
  module HashMergers
    class Config < HashMerger
      private

      def load_yaml(section, section_name)
        args = [section_name].compact
        config_file = file_path.send("#{section}_config", *args)
        Data.load(config_file)
      end
    end
  end
end
