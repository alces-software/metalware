
# frozen_string_literal: true

require 'staging'

module Metalware
  module BuildMethods
    class BuildMethod
      def initialize(metal_config, node)
        @metal_config = metal_config
        @node = node
      end

      def render_staging_templates
        Staging.template(metal_config) do |templator|
          staging_templates.each { |t| render_to_staging(templator, t) }
          render_build_files_to_staging(templator)
        end
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

      attr_reader :metal_config, :node

      delegate :template_path, to: :file_path

      def staging_templates
        raise NotImplementedError
      end

      def file_path
        @file_path ||= FilePath.new(metal_config)
      end

      def render_build_files_to_staging(templater)
        node.files.each do |namespace, files|
          files.each do |file|
            next if file[:error]
            render_path = file_path.rendered_build_file_path(
              node.name,
              namespace,
              file[:name]
            )
            templater.render(node, file[:template_path], render_path)
          end
        end
      end

      def render_to_staging(templater, template_type, sync: nil)
        template_type_path = template_path template_type, node: node
        sync ||= file_path.template_save_path(template_type, node: node)
        templater.render(node, template_type_path, sync)
      end
    end
  end
end
