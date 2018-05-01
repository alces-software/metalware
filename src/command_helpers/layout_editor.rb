# frozen_string_literal: true

require 'validation/asset'

module Metalware
  module CommandHelpers
    class LayoutEditor < BaseCommand
      private

      attr_accessor :node

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

      def copy_and_edit_record_file
        Utils::Editor.open_copy(source, destination) do |edited_path|
          Validation::Asset.valid_file?(edited_path)
        end
      end

      def raise_error_if_node_is_missing
        return if node
        raise InvalidInput, <<-EOF
          Can not find node: #{options.node}
        EOF
      end

      def source
        raise NotImplementedError
      end

      def destination
        raise NotImplementedError
      end
    end
  end
end
