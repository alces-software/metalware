
# frozen_string_literal: true

require 'file_path'
require 'data'
require 'recursive-open-struct'
require 'constants'

module Metalware
  module Utils
    class MergedHash
      HASH_DATA_STRUCTURE = RecursiveOpenStruct

      def initialize(metalware_config, groups: [], node: nil)
        @metalware_config = metalware_config
        @file_path = FilePath.new(metalware_config)
        @groups = groups
        @node = node
      end

      def config
        @config ||= build_hash_for_key(:config)
      end

      private

      attr_reader :metalware_config, :file_path, :groups, :node

      def build_hash_for_key(key)
        HASH_DATA_STRUCTURE.new(combine_hashes(hash_array(key)))
      end

      ##
      # hash_array enforces the order in which the hashes are loaded, it is not
      # responsible for how the file is loaded as that is delegated to load_yaml
      #
      def hash_array(key)
        [ load_yaml(key, :domain) ].tap do |arr|
          groups.each { |group| arr.push(load_yaml(key, :group, group)) }
          arr.push(load_yaml(key, :node, node)) if node
        end
      end

      def load_yaml(key, section, section_name = nil)
        input = (section_name ? [section_name] : [])
        if key == :config
          Data.load(file_path.send("#{section}_config", *input))
        end
      end

      def combine_hashes(hashes)
        hashes.each_with_object({}) do |config, combined_config|
          raise CombineHashError unless config.is_a? Hash
          combined_config.deep_merge!(config)
        end
      end
    end
  end
end