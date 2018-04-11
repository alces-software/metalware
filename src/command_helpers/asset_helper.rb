# frozen_string_literal: true

require 'utils/editor'

module Metalware
  module CommandHelpers
    module AssetHelper
      private

      def edit_asset_file(file)
        copy_and_edit_asset_file(file, file)
      end

      def copy_and_edit_asset_file(source, destination)
        Utils::Editor.open_copy(source, destination) do |edited_path|
          begin
            Metalware::Data.load(edited_path).is_a?(Hash)
          rescue
            false
          end
        end
      end
    end
  end
end
