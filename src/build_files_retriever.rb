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
  BuildFilesRetriever = Struct.new(:metal_config) do
    def retrieve_for_node(node)
      retrieve(node, node.name)
    end

    private

    def retrieve(namespace, files_dir)
      # `input` is passed in to RetrievalProcess (rather than intialized within
      # it, which would still work) so that a shared cache is used for
      # retrieving all files for this BuildFilesRetriever, to avoid duplicate
      # retrievals of the same remote URLs across different RetrievalProcesses.
      RetrievalProcess.new(
        metal_config: metal_config,
        input: input,
        namespace: namespace,
        files_dir: files_dir,
      ).retrieve
    end

    def input
      @input ||= Input::Cache.new
    end

    RetrievalProcess = KeywordStruct.new(
      :metal_config,
      :input,
      :namespace,
      :files_dir
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
            url: DeploymentServer.build_file_url(files_dir, section, name)
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

      def success_file_hash(identifier, template_path:, url:)
        base_file_hash(identifier).merge(
          template_path: template_path,
          url: url
        )
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
          # Path is within the repo `files` directory.
          repo_template_path(identifier)
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

      def repo_template_path(identifier)
        File.join(metal_config.repo_path, 'files', identifier)
      end
    end
  end
end
