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
    class Cache
      def retrieve(namespace)
        BuildFilesRetriever.new(input, namespace)
                           .retrieve
      end

      def input
        @input ||= Input::Cache.new
      end
    end

    def self.cache
      Cache.new
    end

    attr_reader :input, :namespace

    def initialize(input, namespace)
      @input = input
      @namespace = namespace
      klass = namespace.class
      return if [Namespaces::Plugin, Namespaces::Node].include?(klass)
      raise InternalError, 'The namespace is not a node or a plugin'
    end

    def retrieve
      files.to_h.keys.map do |section|
        retrieve_for_section(section)
      end.to_h
    end

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
          rendered_path: FilePath.rendered_build_file_path(
            rendered_dir, section, name
          ),
          url: DeploymentServer.build_file_url(rendered_dir, section, name)
        )
      else
        error_file_hash(
          identifier,
          error: <<-EOF
            Template path '#{template}' for '#{identifier}' does not exist
          EOF
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

    def rendered_dir
      node, files_dir =
        if namespace.is_a?(Namespaces::Plugin)
          [namespace.node_namespace, File.join('plugin', namespace.name)]
        else
          [namespace, 'repo']
        end
      File.join(node.name, 'files', files_dir)
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
      base_path = if namespace.is_a?(Namespaces::Plugin)
                    namespace.plugin.path
                  else
                    FilePath.repo
                  end
      File.join(base_path, 'files', identifier)
    end
  end
end
