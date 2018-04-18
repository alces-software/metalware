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

module Metalware
  module Plugins
    ConfigureQuestionsBuilder = Struct.new(:plugin) do
      private_class_method :new

      def self.build(plugin)
        new(plugin).build
      end

      def build
        Constants::CONFIGURE_SECTIONS.map do |section|
          [section, question_hash_for_section(section)]
        end.to_h
      end

      private

      def question_hash_for_section(section)
        {
          identifier: plugin.enabled_question_identifier,
          question: "Should '#{plugin.name}' plugin be enabled for #{section}?",
          type: 'boolean',
          dependent: questions_for_section(section),
        }
      end

      def questions_for_section(section)
        question_tree[section].map { |q| namespace_question_hash(q) }
      end

      def question_tree
        @question_tree ||= default_configure_data.merge(
          Data.load(configure_file_path)
        )
      end

      def default_configure_data
        Constants::CONFIGURE_SECTIONS.map do |section|
          [section, []]
        end.to_h
      end

      def configure_file_path
        File.join(plugin.path, 'configure.yaml')
      end

      def namespace_question_hash(question_hash)
        # Prepend plugin name to question text, as well as recursively to all
        # dependent questions, so source of plugin questions is clear when
        # configuring.
        question_hash.map do |k, v|
          new_value = case k
                      when :question
                        "#{plugin_identifier} #{v}"
                      when :dependent
                        v.map { |q| namespace_question_hash(q) }
                      else
                        v
                      end
          [k, new_value]
        end.to_h
      end

      def plugin_identifier
        "[#{plugin.name}]"
      end
    end
  end
end
