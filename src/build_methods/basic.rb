
# frozen_string_literal: true

module Metalware
  module BuildMethods
    class Basic < BuildMethod
      TEMPLATES = [:basic].freeze

      private

      def staging_templates
        [:basic]
      end
    end
  end
end
