# frozen_string_literal: true

module Metalware
  module Commands
    module Layout
      class Edit < CommandHelpers::LayoutEditor
        private

        attr_reader :layout_name, :layout_path

        alias source layout_path
        alias destination source

        def setup
          @layout_name = args[0]
          @layout_path = Records::Layout.path(layout_name, missing_error: true)
        end
      end
    end
  end
end
