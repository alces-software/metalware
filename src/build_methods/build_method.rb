
# frozen_string_literal: true

module Metalware
  module BuildMethods
    class BuildMethod
      def initialize(config, node)
        @config = config
        @node = node
      end

      def render_build_started_templates(_parameters)
        raise NotImplementedError
      end

      def render_build_complete_templates(_parameters)
        raise NotImplementedError
      end

      def template_paths
        self.class::TEMPLATES.map do |template_type|
          full_template_path = template_path(template_type, node: node)
          file_path.repo_relative_path_to(full_template_path)
        end
      end

      private

      attr_reader :config, :node

      delegate :template_path, to: :file_path

      def file_path
        @file_path ||= FilePath.new(config)
      end

      def render_template(template_type, parameters:, save_path: nil)
        template_type_path = template_path template_type, node: node
        save_path ||= File.join(
          config.rendered_files_path, template_type.to_s, node.name
        )
        Templater.render_to_file(config, template_type_path, save_path, parameters)
      end
    end
  end
end
