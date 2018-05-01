# frozen_string_literal: true

require 'command_helpers/layout_editor'
require 'asset_builder'

module Metalware
  module CommandHelpers
    class AssetEditor < LayoutEditor
      private

      attr_reader :asset_name

      def run
        copy_and_edit_record_file
        assign_asset_to_node_if_given
      end

      def asset_builder
        @asset_builder ||= AssetBuilder.new
      end

      def node
        @node ||= begin
          if options.node
            alces.nodes.find_by_name(options.node).tap do |n|
              raise_error_if_node_is_missing(n)
            end
          end
         end
      end

      def assign_asset_to_node_if_given
        return unless node
        Cache::Asset.update do |cache|
          cache.assign_asset_to_node(asset_name, node)
        end
      end

      def raise_error_if_node_is_missing(node_input)
        return if node_input
        raise InvalidInput, <<-EOF
          Unable to find node: #{options.node}
        EOF
      end
    end
  end
end
