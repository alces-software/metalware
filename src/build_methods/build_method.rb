
# frozen_string_literal: true

require 'staging'

module Metalware
  module BuildMethods
    class BuildMethod
      def initialize(metal_config, node)
        @metal_config = metal_config
        @node = node
      end

      # TODO: Change name to staging_hook
      def render_staging_templates
        Staging.template(metal_config) do |templator|
          staging_templates.each { |t| render_to_staging(templator, t) }
          render_build_files_to_staging(templator)
        end
      end

      def start_hook
        # Runs at the start of the build process
      end

      def complete_hook
        # Runs after the nodes have reported built
      end

      def dependency_paths
        staging_templates.map do |t|
          strip_leading_repo_path(file_path.template_path(t, node: node))
        end
      end

      private

      attr_reader :metal_config, :node

      def strip_leading_repo_path(path)
        path.gsub(/^#{file_path.repo}\/?/, '')
      end

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
            templater.render(node, file[:template_path], render_path, mkdir: true)
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
