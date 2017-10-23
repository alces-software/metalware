
# frozen_string_literal: true

module Metalware
  module BuildMethods
    class Basic < BuildMethod
      TEMPLATES = [:basic].freeze

      def render_build_start_templates
        render_basic(DEFAULT_BUILD_START_PARAMETERS)
      end

      private

      def render_basic(parameters)
        render_template(:basic, parameters: parameters)
      end
    end
  end
end
