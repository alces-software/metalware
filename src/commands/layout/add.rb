# frozen_string_literal: true

require 'utils/editor'
require 'records/layout'

module Metalware
  module Commands
    module Layout
      class Add < CommandHelpers::LayoutEditor
        private

        attr_reader :type_name, :layout_name

        def setup
          @type_name = args[0]
          @layout_name = args[1]
        end

        def run
          source # This ensures that the source type is valid
          Records::Layout.error_if_unavailable(layout_name)
          FileUtils.mkdir_p File.dirname(destination)
          copy_and_edit_record_file
        end

        def destination
          FilePath.layout(type_name.pluralize, layout_name)
        end

        def source
          FilePath.asset_type(type_name).tap do |path|
            raise_missing_asset_type unless File.exist?(path)
          end
        end

        def raise_missing_asset_type
          raise InvalidInput, <<-EOF.squish
            Cannot find asset type: "#{type_name}"
          EOF
        end
      end
    end
  end
end
