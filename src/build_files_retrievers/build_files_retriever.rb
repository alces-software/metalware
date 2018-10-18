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

module Metalware
  module BuildFilesRetrievers
    class BuildFilesRetriever
      attr_reader :cache, :namespace

      def initialize(cache, namespace)
        @cache = cache
        @namespace = namespace
      end

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
        if identifier.match?(URI::DEFAULT_PARSER.make_regexp)
          # Download the template to the Metalware cache
          # will render it from there.
          cache.download(identifier)
        elsif Pathname.new(identifier).absolute?
          # Path is an absolute path on the deployment server.
          identifier
        else
          # Path is internal within the given templates directory.
          internal_template_path(identifier)
        end
      end

      def rendered_dir
        File.join(node.name, 'files', rendered_sub_dir)
      end

      def internal_template_path(identifier)
        File.join(local_template_dir, 'files', identifier)
      end

      def node
        raise NotImplementedError
      end

      def rendered_sub_dir
        raise NotImplementedError
      end

      def local_template_dir
        raise NotImplementedError
      end
    end
  end
end
