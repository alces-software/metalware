
# frozen_string_literal: true

module Metalware
  module BuildMethods
    class Self < BuildMethod
      TEMPLATES = [:self].freeze

      def render_build_started_templates(parameters)
        render_template(:self, parameters: parameters)
      end

      def render_build_complete_templates(_parameters); end

      private
    end
  end
end
