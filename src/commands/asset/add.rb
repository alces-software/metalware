# frozen_string_literal: true

require 'utils/editor'

module Metalware
  module Commands
    module Asset
      class Add < CommandHelpers::RecordEditor
        private

        attr_reader :type_name, :type_path, :asset_path, :asset_name

        alias source type_path
        alias destination asset_path

        def setup
          @type_name = args[0]
          @type_path = FilePath.asset_type(type_name)
          @asset_name = args[1]
          @asset_path = FilePath.asset(asset_name)
          unpack_node_from_options
        end

        def run
          error_if_type_is_missing
          error_if_asset_exists
          copy_and_edit_record_file
          assign_asset_to_node_if_given(asset_name)
        end

        def error_if_type_is_missing
          return if File.exist?(type_path)
          raise InvalidInput, <<-EOF.squish
            Cannot find asset type: "#{type_name}"
          EOF
        end

        def error_if_asset_exists
          return unless File.exist?(asset_path)
          raise InvalidInput, <<-EOF.squish
            The "#{asset_name}" asset already exists. Please use `metal
            asset edit` instead
          EOF
        end
      end
    end
  end
end
