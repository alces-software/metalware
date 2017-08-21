
# frozen_string_literal: true

module Metalware
  module BuildMethods
    class Basic < BuildMethod
      def render_build_started_templates(parameters)
        render_basic(parameters)
      end

      def render_build_complete_templates(_parameters); end

      def template_paths
        [:basic].map do |template_type|
          full_template_path = template_path(template_type, node: node)
          file_path.repo_relative_path_to(full_template_path)
        end
      end

      private

      def render_basic(parameters)
        render_template(:basic, parameters: parameters)
      end
    end
  end
end
