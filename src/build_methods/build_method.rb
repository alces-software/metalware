
# frozen_string_literal: true

require 'staging'
require 'keyword_struct'

module Metalware
  module BuildMethods
    class BuildMethod
      def initialize(metal_config, node)
        @metal_config = metal_config
        @node = node
        @file_path = FilePath # Inherited class still require file_path
      end

      def render_staging_templates(templater)
        staging_templates.each { |t| render_to_staging(templater, t) }
        render_build_files_to_staging(templater)
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

      attr_reader :metal_config, :node, :file_path

      def strip_leading_repo_path(path)
        path.gsub(/^#{FilePath.repo}\/?/, '')
      end

      def staging_templates
        raise NotImplementedError
      end

      def render_build_files_to_staging(templater)
        BuildFilesRenderer.new(templater: templater, namespace: node).render
        node.plugins.map do |plugin|
          BuildFilesRenderer.new(templater: templater, namespace: plugin).render
        end
      end

      def render_to_staging(templater, template_type, sync: nil)
        template_type_path = FilePath.template_path(template_type, node: node)
        sync ||= FilePath.template_save_path(template_type, node: node)
        templater.render(node, template_type_path, sync)
      end

      BuildFilesRenderer = KeywordStruct.new(:templater, :namespace) do
        def render
          namespace.files.each do |_section, files|
            files.select { |file| file[:error].nil? }.map do |file|
              templater.render(
                namespace,
                file[:template_path],
                file[:rendered_path],
                mkdir: true
              )
            end
          end
        end
      end
    end
  end
end
