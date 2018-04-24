# frozen_string_literal: true

module Metalware
  module Commands
    module Asset
      class Edit < CommandHelpers::RecordEditor
        private

        attr_reader :asset_name, :asset_path

        alias source asset_path
        alias destination source

        def setup
          @asset_name = args[0]
          @asset_path = asset_path_or_error_if_missing(asset_name)
          unpack_node_from_options
        end

        def run
          copy_and_edit_record_file
          assign_asset_to_node_if_given(asset_name)
        end
      end
    end
  end
end
