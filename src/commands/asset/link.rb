# frozen_string_literal: true

module Metalware
  module Commands
    module Asset
      class Link < Metalware::CommandHelpers::RecordEditor

        private

        attr_reader :asset_name, :asset_path

        def setup
          @asset_name = args[1]
          @asset_path = FilePath.asset(asset_name)
          @node = alces.nodes.find_by_name(args[0])
        end

        def run
          error_if_record_file_does_not_exist(asset_path)
          assign_asset_to_node_if_given(asset_name)
        end
      end
    end
  end
end
