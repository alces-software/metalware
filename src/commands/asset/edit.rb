# frozen_string_literal: true

module Metalware
  module Commands
    module Asset
      class Edit < Metalware::CommandHelpers::RecordEditor
        private

        attr_reader :asset_name, :asset_path

        def setup
          @asset_name = args[0]
          @asset_path = FilePath.asset(asset_name)
          unpack_node_from_options
        end

        def run
          error_if_record_file_does_not_exist(asset_path)
          copy_and_edit_record_file
          assign_asset_to_node_if_given(asset_name)
        end

        def source
          asset_path
        end

        def destination
          source
        end
      end
    end
  end
end
