
# frozen_string_literal: true

module Metalware
  module BuildMethods
    class Basic < BuildMethod
      TEMPLATES = [:basic].freeze

      def render_build_started_templates(parameters)
        render_basic(parameters)
      end

      def render_build_complete_templates(_parameters); end

      private

      def render_basic(_parameters)
        # TODO: Is the parameters still required?
        render_template(:basic, parameters: {}) # parameters)
      end
    end
  end
end
