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

    let :example_plugin_dir do
      File.join(Metalware::FilePath.plugins_dir, 'example')
    end

    let :sections_to_loaded_questions do
      configure_sections.map do |section|
        [section, subject.configure_data[section].children]
      end.to_h
    end

    RSpec.shared_examples 'loads_repo_configure_questions' do |section|
      it 'loads repo configure.yaml questions' do
        questions = sections_to_loaded_questions[section]
        question_identifiers = questions.map { |q| q.content.identifier }
        expect(question_identifiers).to include "#{section}_identifier"
      end
    end

    RSpec.shared_examples 'includes_generated_plugin_enabled_question' do |section|
      it 'includes generated plugin enabled question' do
        question_content = plugin_enabled_question.content

        expect(
          question_content.question
        ).to eq "Should 'example' plugin be enabled for #{section}?"
        expect(
          question_content.type
        ).to eq 'boolean'
      end
    end

    subject do
      described_class.new(config)
    end

    before :each do
      FileSystem.root_setup do |fs|
        fs.dump(Metalware::FilePath.configure_file, configure_questions_hash)

        # Create example plugin.
        fs.mkdir_p example_plugin_dir
        example_plugin_configure_file = File.join(example_plugin_dir, 'configure.yaml')
        fs.dump(example_plugin_configure_file, example_plugin_configure_questions_hash)
      end
    end

    after :each do
      Metalware::Config.clear_cache
    end

    Metalware::Constants::CONFIGURE_SECTIONS.each do |section|
      context "for #{section}" do

        context 'when no plugins enabled' do
          include_examples 'loads_repo_configure_questions', section
        end

        context 'when plugin enabled' do
          before :each do
            FileSystem.root_setup do |fs|
              fs.enable_plugin('example')
            end
          end

          # XXX Extract class for handling internal configure identifiers.
          let :plugin_enabled_question_identifier { 'metalware_internal--plugin_enabled--example' }

          let :plugin_enabled_question do
            questions = sections_to_loaded_questions[section]
            questions.find do |question|
              question.content.identifier == plugin_enabled_question_identifier
            end
          end

          include_examples 'loads_repo_configure_questions', section
          include_examples 'includes_generated_plugin_enabled_question', section

          it "generated question includes plugin questions for #{section} as dependents" do
            plugin_question = plugin_enabled_question.children.first
            plugin_question_content = plugin_question.content
            expect(plugin_question_content.identifier).to eq "example_plugin_#{section}_identifier"

            # NOTE: plugin name has been prepended to question to indicate
            # where this question comes from.
            expect(plugin_question_content.question).to eq "[example] example_plugin_#{section}_question"

            plugin_dependent_question = plugin_question.children.first

            # As above, plugin name has been prepended to dependent question.
            expect(
              plugin_dependent_question.content.question
            ).to eq "[example] example_plugin_#{section}_dependent_question"
          end

          context 'when no configure.yaml for plugin' do
            before :each do
              FileSystem.root_setup do |fs|
                fs.rm_rf example_plugin_dir
                fs.mkdir_p example_plugin_dir
              end
            end

            include_examples 'includes_generated_plugin_enabled_question', section

            it 'generated question has no dependents' do
              expect(plugin_enabled_question.children).to be_empty
            end
          end
        end
      end
    end
  end
end
