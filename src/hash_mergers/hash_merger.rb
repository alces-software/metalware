
# frozen_string_literal: true

require 'file_path'
require 'validation/loader'
require 'data'
require 'constants'

module Metalware
  module HashMergers
    class HashMerger
      def initialize(metalware_config)
        @metalware_config = metalware_config
        @file_path = FilePath.new(metalware_config)
        @loader = Validation::Loader.new(metalware_config, cache_configure: true)
        @cache = {}
      end

      def merge(groups: [], node: nil, &templater_block)
        arr = hash_array(groups: groups, node: node)
        Constants::HASH_MERGER_DATA_STRUCTURE
          .new(combine_hashes(arr), &templater_block)
      end

      private

      attr_reader :metalware_config, :file_path, :loader, :cache

      ##
      # hash_array enforces the order in which the hashes are loaded, it is
      # not responsible for how the file is loaded as that is delegated to
      # load_yaml
      #
      def hash_array(groups:, node:)
        [cached_yaml(:domain)].tap do |arr|
          groups.each { |group| arr.push(cached_yaml(:group, group)) }
          arr.push(cached_yaml(:node, node)) if node
        end
      end

      def cached_yaml(section, section_name = nil)
        data = cached_data(section, section_name)
        return data if data
        data = load_yaml(section, section_name)
        add_cached_data(section, section_name, data)
        data
      end

      def cached_data(section, section_name)
        if section_name
          cache_section = cache[section]
          return nil unless cache_section
          cache_section[section_name]
        else
          no_section_name = cache[:no_section_name]
          return nil unless no_section_name
          no_section_name[section]
        end
      end

      def add_cached_data(section, section_name, data)
        if section_name
          cache[section] = {} unless cache[section]
          cache[section][section_name] = data
        else
          cache[:no_section_name] = {} unless cache[:no_section_name]
          cache[:no_section_name][section] = data
        end
      end

      def load_yaml(_section, _section_name)
        raise NotImplementedError
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
