# frozen_string_literal: true

require 'utils/editor'
require 'records/layout'

module Metalware
  module Commands
    module Layout
      class Add < CommandHelpers::LayoutEditor
        private

        attr_reader :template, :layout_name

        def setup
          @template = Records::Layout.type_or_layout(args[0])
          @layout_name = args[1]
          source # This ensures that the source type is valid
          Records::Layout.error_if_unavailable(layout_name)
          FileUtils.mkdir_p File.dirname(destination)
        end

        def destination
          FilePath.layout(template.type.pluralize, layout_name)
        end

        def source
          raise_missing_asset_type_or_layout if template.nil?
          template.path
        end

        def raise_missing_asset_type_or_layout
          raise InvalidInput, <<-EOF.squish
            Could not find asset type or layout: "#{args[0]}"
          EOF
        end
      end
    end
  end
end
