# frozen_string_literal: true

require 'utils/editor'
require 'records/layout'

module Metalware
  module Commands
    module Layout
      class Add < CommandHelpers::RecordEditor
        private

        attr_reader :type_name, :type_path, :layout_name

        alias source type_path

        def setup
          @type_name = args[0]
          @type_path = FilePath.asset_type(type_name)
          @layout_name = args[1]
        end

        def run
          error_if_type_is_missing
          ensure_layout_name_is_available
          FileUtils.mkdir_p File.dirname(destination)
          copy_and_edit_record_file
        end

        def destination
          FilePath.layout(type_name.pluralize, layout_name)
        end

        def error_if_type_is_missing
          return if File.exist?(type_path)
          raise InvalidInput, <<-EOF.squish
            Cannot find layout type: "#{type_name}"
          EOF
        end

        def ensure_layout_name_is_available
          return if Records::Layout.available?(layout_name)
          msg = if Records::Layout.path(layout_name)
                  <<-EOF.squish
                    The "#{layout_name}" layout already exists. Please use
                    'metal layout edit' instead
                  EOF
                else
                  "\"#{layout_name}\" is not a valid layout name"
                end
          raise InvalidInput, msg
        end
      end
    end
  end
end
