# frozen_string_literal: true

require 'validation/asset'

module Metalware
  module CommandHelpers
    class LayoutEditor < BaseCommand
      private

      def run
        copy_and_edit_record_file
      end

      def type_or_layout(name)
        if Records::Asset::TYPES.include?(name)
          OpenStruct.new(
            type: name,
            path: FilePath.asset_type(name)
          )
        elsif (path = Records::Layout.path(name))
          OpenStruct.new(
            type: Records::Layout.type_from_path(path),
            path: path
          )
        end
      end

      def copy_and_edit_record_file
        Utils::Editor.open_copy(source, destination) do |edited_path|
          Validation::Asset.valid_file?(edited_path)
        end
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
