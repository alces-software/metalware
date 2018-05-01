# frozen_string_literal: true

require 'command_helpers/layout_editor'
require 'asset_builder'

module Metalware
  module CommandHelpers
    class AssetEditor < LayoutEditor
      private

      attr_accessor :node

      def run
        copy_and_edit_record_file
        assign_asset_to_node_if_given(asset_name)
      end

      def asset_builder
        @asset_builder ||= AssetBuilder.new
      end

      def unpack_node_from_options
        return unless options.node
        self.node = alces.nodes.find_by_name(options.node)
        raise_error_if_node_is_missing
      end

      def assign_asset_to_node_if_given(asset_name)
        return unless node
        Cache::Asset.update do |cache|
          cache.assign_asset_to_node(asset_name, node)
        end
      end

      def raise_error_if_node_is_missing
        return if node
        raise InvalidInput, <<-EOF
          Unable to find node: #{options.node}
        EOF
      end
    end
  end
end
