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

require 'nodeattr_interface'
require 'active_support/core_ext/string/strip'
require 'data'
require 'staging'
require 'render_methods'

module Metalware
  module Commands
    module Remove
      class Group < CommandHelpers::BaseCommand
        def setup
          @primary_group = args[0]
          @cache = GroupCache.new
        end

        def run
          delete_answer_files
          cache.remove(primary_group)
          Staging.template do |templater|
            RenderMethods::Genders.render_to_staging(alces.domain, templater)
          end
        end

        private

        attr_reader :primary_group, :cache

        def dependency_hash
          {
            configure: ["groups/#{primary_group}.yaml"],
          }
        end

        def delete_answer_files
          list_of_answer_files.each do |file|
            File.delete(file) if File.file?(file)
          end
        end

        def list_of_answer_files
          NodeattrInterface.nodes_in_group(primary_group)
                           .map { |node| FilePath.node_answers(node) }
                           .unshift(FilePath.group_answers(primary_group))
        end
      end
    end
  end
end
