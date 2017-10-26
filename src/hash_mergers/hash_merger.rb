
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
          groups.reverse.each do |group|
            arr.push(cached_yaml(:group, group))
          end
          if node == 'local'
            arr.push(cached_yaml(:local))
          elsif node
            arr.push(cached_yaml(:node, node))
          end
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
        hashes.each_with_object(files: {}) do |config, combined_config|
          config = config.dup # Prevents the cache being deleted
          raise CombineHashError unless config.is_a? Hash
          files = config.delete(:files)
          combined_config.deep_merge!(config)
          merge_in_files!(combined_config[:files], files)
        end
      end

      def merge_in_files!(existing_files, new_files)
        new_files&.each do |namespace, file_identifiers|
          file_identifiers.each do |file_identifier|
            existing_files[namespace] = [] unless existing_files[namespace]
            replace_file_with_same_basename!(existing_files[namespace], file_identifier)
          end
        end
      end

      def replace_file_with_same_basename!(files_namespace, file_identifier)
        files_namespace.reject! { |f| same_basename?(file_identifier, f) }
        files_namespace << file_identifier
        files_namespace.sort! # Sort for consistent ordering.
      end

      def same_basename?(path1, path2)
        File.basename(path1) == File.basename(path2)
      end
    end
  end
end
