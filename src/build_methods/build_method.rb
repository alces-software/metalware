
# frozen_string_literal: true

module Metalware
  module BuildMethods
    class BuildMethod
      def initialize(config, node)
        @config = config
        @node = node
      end

      def render_build_start_templates
        raise NotImplementedError
      end

      def render_build_complete_templates
      end

      def template_paths
        self.class::TEMPLATES.map do |template_type|
          full_template_path = template_path(template_type, node: node)
          file_path.repo_relative_path_to(full_template_path)
        end
      end

      def start_build
        # Runs after the files have been rendered but before build waits
        # for the nodes to complete. Leave blank if the nodes build need to
        # be started manually by powering them on.
      end

      private

      DEFAULT_BUILD_START_PARAMETERS = {
        firstboot: true,
      }

      DEFAULT_BUILD_COMPLETE_PARAMETERS = {
        firstboot: false,
      }

      attr_reader :config, :node

      delegate :template_path, to: :file_path

      def file_path
        @file_path ||= FilePath.new(config)
      end

      def render_template(template_type, parameters:, save_path: nil)
        template_type_path = template_path template_type, node: node
        save_path ||= file_path.template_save_path(template_type, node: node)
        Templater.render_to_file(node,
                                 template_type_path,
                                 save_path,
                                 **parameters.to_h)
      end
    end
  end
end
