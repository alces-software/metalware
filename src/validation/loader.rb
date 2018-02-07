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

require 'file_path'
require 'validation/answer'
require 'validation/configure'
require 'validation/load_save_base'
require 'data'

module Metalware
  module Validation
    class Loader < LoadSaveBase
      def initialize
        @path = FilePath
      end

      def configure_data
        # XXX Extract object for loading configure data?
        @configure_data ||=
          Validation::Configure.new(Config.new, combined_configure_data).tree
      end

      # Returns a tree
      def configure_section(section)
        configure_data.children.find { |c| c.name == section }
      end

      # Returns a hash of identifiers and questions
      def flattened_configure_section(section)
        section_root = configure_section(section)
        section_root.each_with_object({}) do |node, memo|
          next if section_root == node
          memo[node.name.to_sym] = node.content
        end
      end

      def group_cache
        Data.load(path.group_cache)
      end

      private

      attr_reader :path

      def answer(absolute_path, section)
        yaml = Data.load(absolute_path)
        validator = Validation::Answer.new(yaml,
                                           answer_section: section,
                                           configure_data: configure_data)
        validator.data
      end

      def combined_configure_data
        Constants::CONFIGURE_SECTIONS.map do |section|
          [section, all_questions_for_section(section)]
        end.to_h
      end

      def all_questions_for_section(section)
        [
          repo_configure_questions,
          *plugin_configure_questions,
        ].flat_map do |question_group|
          question_group[section]
        end
      end

      def repo_configure_questions
        @repo_configure_questions ||= Data.load(FilePath.configure_file)
      end

      def plugin_configure_questions
        @plugin_configure_questions ||=
          Plugins.activated.map(&:configure_questions)
      end
    end
  end
end
