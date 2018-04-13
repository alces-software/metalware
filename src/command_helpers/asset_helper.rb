# frozen_string_literal: true

require 'utils/editor'
require 'cache/asset'

module Metalware
  module CommandHelpers
    module AssetHelper
      private

      attr_accessor :node

      def asset_cache
        @asset_cache ||= Cache::Asset.new
      end

      def unpack_node_from_options
        return unless options.node
        self.node = alces.nodes.find_by_name(options.node)
        raise_error_if_node_is_missing
      end

      def assign_asset_to_node_if_given(asset_name)
        return unless node
        asset_cache.assign_asset_to_node(asset_name, node)
        asset_cache.save
      end

      def edit_asset_file(file)
        copy_and_edit_asset_file(file, file)
      end

      def copy_and_edit_asset_file(source, destination)
        Utils::Editor.open_copy(source, destination) do |edited_path|
          begin
            Metalware::Data.load(edited_path).is_a?(Hash)
          rescue StandardError
            false
          end
        end
      end

      def raise_error_if_node_is_missing
        return if node
        raise InvalidInput, <<-EOF
          Can not find node: #{options.node}
        EOF
      end

      def error_if_asset_file_doesnt_exist(asset_path)
        asset_name = File.basename(asset_path, '.*')
        return if File.exist?(asset_path)
        raise InvalidInput, <<-EOF.squish
          The "#{asset_name}" asset does not exist
        EOF
      end
    end
  end
end
