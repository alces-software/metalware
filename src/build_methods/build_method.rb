
# frozen_string_literal: true

module Metalware
  module BuildMethods
    class BuildMethod
      def initialize(config, node)
        @config = config
        @node = node
      end

      def render_staging_templates
        staging_templates.each { |t| render_to_staging(t) }
        render_build_files_to_staging
      end

      # TODO: Remove this once all build methods use the staging
      def render_build_start_templates
        raise NotImplementedError
      end

      # TODO: Change the name to match the build complete hook
      def render_build_complete_templates; end

      # TODO: Remove this if not required in refactor
      def template_paths
        self.class::TEMPLATES.map do |template_type|
          full_template_path = template_path(template_type, node: node)
          file_path.repo_relative_path_to(full_template_path)
        end
      end

      # TODO: Change to build start hook
      def start_build
        # Runs after the files have been rendered but before build waits
        # for the nodes to complete. Leave blank if the nodes build need to
        # be started manually by powering them on.
      end

      private

      DEFAULT_BUILD_START_PARAMETERS = {
        firstboot: true,
      }.freeze

      DEFAULT_BUILD_COMPLETE_PARAMETERS = {
        firstboot: false,
      }.freeze

      attr_reader :config, :node

      delegate :template_path, to: :file_path

      def staging_templates
        raise NotImplementedError
      end

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

      def render_build_files_to_staging
        node.files.each do |namespace, files|
          files.each do |file|
            next if file[:error]
            render_path = file_path.rendered_build_file_path(node.name,
                                                             namespace,
                                                             file[:name])
            templater.render_to_staging(node,
                                        file[:template_path],
                                        render_path)
          end
        end
      end

      def render_to_staging(template_type, sync: nil)
        template_type_path = template_path template_type, node: node
        sync ||= file_path.template_save_path(template_type, node: node)
        templater.render_to_staging(node,
                                    template_type_path,
                                    sync)
      end

      def templater
        @templater ||= Templater.new(config)
      end
    end
  end
end
