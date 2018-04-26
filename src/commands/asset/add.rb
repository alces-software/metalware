# frozen_string_literal: true

require 'utils/editor'

module Metalware
  module Commands
    module Asset
      class Add < CommandHelpers::RecordEditor
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
          ensure_asset_name_is_available
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

        def ensure_asset_name_is_available
          return if Records::Asset.available?(asset_name)
          msg = if Records::Asset.path(asset_name)
                  <<-EOF.squish
                    The "#{asset_name}" asset already exists. Please use
                    `metal asset edit` instead
                  EOF
                else
                  "\"#{asset_name}\" is not a valid asset name"
                end
          raise InvalidInput, msg
        end
      end
    end
  end
end
