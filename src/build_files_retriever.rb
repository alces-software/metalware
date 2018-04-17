# frozen_string_literal: true

#==============================================================================
# Copyright (C) 2017 Stephen F. Norledge and Alces Software Ltd.
#
# This file/package is part of Alces Metalware.
#
# Alces Metalware is free software: you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License
# as published by the Free Software Foundation, either version 3 of
# the License, or (at your option) any later version.
#
# Alces Metalware is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this package.  If not, see <http://www.gnu.org/licenses/>.
#
# For more information on the Alces Metalware, please visit:
# https://github.com/alces-software/metalware
#==============================================================================

require 'uri'
require 'open-uri'

require 'constants'
require 'input'
require 'keyword_struct'

module Metalware
  class BuildFilesRetriever
    def retrieve_for_node(node_namespace)
      retrieve(
        namespace: node_namespace,
        internal_templates_dir: files_dir_in(FilePath.repo),
        rendered_dir:  rendered_repo_files_dir(node_namespace)
      )
    end

    def retrieve_for_plugin(plugin_namespace)
      retrieve(
        namespace: plugin_namespace,
        internal_templates_dir: files_dir_in(plugin_namespace.plugin.path),
        rendered_dir: rendered_plugin_files_dir(plugin_namespace)
      )
    end

    private

    def rendered_repo_files_dir(node)
      rendered_files_dir(node: node, files_dir: 'repo')
    end

    def rendered_plugin_files_dir(plugin)
      plugin_files_dir = File.join('plugin', plugin.name)
      rendered_files_dir(node: plugin.node_namespace, files_dir: plugin_files_dir)
    end

    def rendered_files_dir(node:, files_dir:)
      File.join(node.name, 'files', files_dir)
    end

    def retrieve(**kwargs)
      # `input` is passed in to RetrievalProcess (rather than intialized within
      # it, which would still work) so that a shared cache is used for
      # retrieving all files for this BuildFilesRetriever, to avoid duplicate
      # retrievals of the same remote URLs across different RetrievalProcesses.
      RetrievalProcess.new(input: input, **kwargs).retrieve
    end

    def input
      @input ||= Input::Cache.new
    end

    def files_dir_in(dir)
      File.join(dir, 'files')
    end

    RetrievalProcess = KeywordStruct.new(
      :input,
      :namespace,
      :internal_templates_dir,
      :rendered_dir
    ) do
      def retrieve
        files.to_h.keys.map do |section|
          retrieve_for_section(section)
        end.to_h
      end

      private

      def retrieve_for_section(section)
        file_hashes = files[section].map do |file|
          file_hash_for(section, file)
        end
        [section, file_hashes]
      end

      def files
        namespace.config.files
      end

      def file_hash_for(section, identifier)
        name = File.basename(identifier)
        template = template_path(identifier)

        if File.exist?(template)
          success_file_hash(
            identifier,
            template_path: template,
            rendered_path: FilePath.rendered_build_file_path(rendered_dir, section, name),
            url: DeploymentServer.build_file_url(rendered_dir, section, name)
          )
        else
          error_file_hash(
            identifier,
            error: "Template path '#{template}' for '#{identifier}' does not exist"
          )
        end
      rescue StandardError => error
        error_file_hash(
          identifier,
          error: "Retrieving '#{identifier}' gave error '#{error.message}'"
        )
      end

      def success_file_hash(identifier, **params)
        base_file_hash(identifier).merge(params)
      end

      def error_file_hash(identifier, error:)
        MetalLog.warn("Build file: #{error}")
        base_file_hash(identifier).merge(
          error: error
        )
      end

      def base_file_hash(identifier)
        name = File.basename(identifier)
        {
          raw: identifier,
          name: name,
        }
      end

      def template_path(identifier)
        name = File.basename(identifier)
        if url?(identifier)
          # Download the template to the Metalware cache; will render it from
          # there.
          cache_template_path(name).tap do |template|
            input.download(identifier, template)
          end
        elsif absolute_path?(identifier)
          # Path is an absolute path on the deployment server.
          identifier
        else
          # Path is internal within the given templates directory.
          internal_template_path(identifier)
        end
      end

      def url?(identifier)
        identifier =~ URI::DEFAULT_PARSER.make_regexp
      end

      def absolute_path?(identifier)
        Pathname.new(identifier).absolute?
      end

      def cache_template_path(template_name)
        File.join(Constants::CACHE_PATH, 'templates', template_name)
      end

      def internal_template_path(identifier)
        File.join(internal_templates_dir, identifier)
      end
    end
  end
end
