# frozen_string_literal: true

module Metalware
  module CommandHelpers
    class RecordEditor < BaseCommand
      private

      include AssetCache

      attr_accessor :node

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

      def copy_and_edit_record_file
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

      def error_if_record_file_does_not_exist(record_path)
        record_name = File.basename(record_path, '.*')
        return if File.exist?(record_path)
        raise InvalidInput, <<-EOF.squish
          The "#{record_name}" record does not exist
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
