# frozen_string_literal: true

require 'utils/editor'

module Metalware
  module Commands
    module Asset
      class Add < CommandHelpers::LayoutEditor
        private

        attr_reader :type_name, :type_path, :asset_name

        alias source type_path

        def setup
          @type_name = args[0]
          @type_path = FilePath.asset_type(type_name)
          @asset_name = args[1]
          unpack_node_from_options
        end

        def run
          error_if_type_is_missing
          Records::Asset.error_if_unavailable(asset_name)
          FileUtils.mkdir_p File.dirname(destination)
          copy_and_edit_record_file
          assign_asset_to_node_if_given(asset_name)
        end

        def destination
          FilePath.asset(type_name.pluralize, asset_name)
        end

        def error_if_type_is_missing
          return if File.exist?(type_path)
          raise InvalidInput, <<-EOF.squish
            Cannot find asset type: "#{type_name}"
          EOF
        end
      end
    end
  end
end
