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

require 'validation/loader'

RSpec.describe Metalware::Validation::Loader do
  describe '#configure_data' do
    let! :config do
      # Need to create and cache a config before each test as this is expected
      # by FilePath.
      Metalware::Config.cache = Metalware::Config.new
    end

    let :configure_sections do
      Metalware::Constants::CONFIGURE_SECTIONS
    end

    let :configure_questions_hash do
      configure_sections.map do |section|
        [
          section, [{
            identifier: "#{section}_identifier",
            question: "#{section}_question",
          }]
        ]
      end.to_h
    end

    let :example_plugin_configure_questions_hash do
      # XXX DRY up parts of this and above?
      configure_sections.map do |section|
        [
          section, [{
            identifier: "example_plugin_#{section}_identifier",
            question: "example_plugin_#{section}_question",
            dependent: [
              {
                identifier: "example_plugin_#{section}_dependent_identifier",
                question: "example_plugin_#{section}_dependent_question",
              }
            ]
          }]
        ]
      end.to_h
    end

    let :filesystem do
      FileSystem.setup do |fs|
        file_path = Metalware::FilePath

        fs.dump(file_path.configure_file, configure_questions_hash)

        # Create example plugin.
        example_plugin_dir = File.join(file_path.plugins_dir, 'example')
        fs.mkdir_p example_plugin_dir
        example_plugin_configure_file = File.join(example_plugin_dir, 'configure.yaml')
        fs.dump(example_plugin_configure_file, example_plugin_configure_questions_hash)
      end
    end

    RSpec.shared_examples 'loads_repo_configure_questions' do
      it 'loads repo configure.yaml questions for all sections' do
        filesystem.test do
          sections_to_loaded_questions = configure_sections.map do |section|
            [section, subject.configure_data[section].children.map(&:content).map(&:to_h)]
          end.to_h

          configure_sections.each do |section|
            questions = sections_to_loaded_questions[section]
            question_identifiers = questions.map { |q| q[:identifier] }
            expect(question_identifiers).to include "#{section}_identifier"
          end
        end
      end
    end

    subject do
      described_class.new(config)
    end

    after :each do
      Metalware::Config.clear_cache
    end

    context 'when no plugins enabled' do
      include_examples 'loads_repo_configure_questions'
    end

    context 'when plugin enabled' do
      before :each do
        filesystem.enable!('example')
      end

      include_examples 'loads_repo_configure_questions'

      # XXX Split this massive test up
      it 'includes generated plugin question with plugin questions as dependents' do
        filesystem.test do
          # XXX DRY up with above
          sections_to_loaded_questions = configure_sections.map do |section|
            [section, subject.configure_data[section].children]
          end.to_h

          # XXX Extract class for handling internal configure identifiers.
          plugin_enabled_identifier = 'metalware_internal--plugin_enabled--example'

          configure_sections.each do |section|
            questions = sections_to_loaded_questions[section]
            question_identifiers = questions.map { |q| q.content.identifier }

            expect(question_identifiers).to include(plugin_enabled_identifier)

            plugin_enabled_question = questions.find do |question|
              question.content.identifier == plugin_enabled_identifier
            end
            question_content = plugin_enabled_question.content

            expect(
              question_content.question
            ).to eq "Should 'example' plugin be enabled for #{section}?"
            expect(
              question_content.type
            ).to eq 'boolean'

            expect(plugin_enabled_question.children.length).to eq 1
            plugin_question = plugin_enabled_question.children.first
            plugin_question_content = plugin_question.content
            expect(plugin_question_content.identifier).to eq "example_plugin_#{section}_identifier"

            # NOTE: plugin name has been prepended to question to indicate
            # where this question comes from.
            expect(plugin_question_content.question).to eq "[example] example_plugin_#{section}_question"

            expect(plugin_question.children.length).to eq 1
            plugin_dependent_question = plugin_question.children.first

            # As above, plugin name has been prepended to dependent question.
            expect(
              plugin_dependent_question.content.question
            ).to eq "[example] example_plugin_#{section}_dependent_question"
          end
        end
      end
    end
  end
end
