
# frozen_string_literal: true

module Metalware
  module BuildMethods
    class BuildMethod
      def initialize(config, node)
        @config = config
        @node = node
      end

      def render_build_started_templates(_parameters)
        # Note: Currently both `BuildMethod` implementations
        # `render_#{template_type}` for each `$template_type` in `TEMPLATES`;
        # if this trend continues we could do this dynamically here and remove
        # this method from the implementations (at the possible expense of
        # understandability).
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

      def start_build
        # Runs after the files have been rendered but before build waits for the
        # nodes to complete. Leave blank if the nodes build need to be started
        # manually by powering them on.
      end

      private

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
                                 **parameters)
      end
    end
  end
end
