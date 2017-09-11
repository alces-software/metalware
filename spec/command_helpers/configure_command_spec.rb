
# frozen_string_literal: true

require 'config'
require 'filesystem'
require 'spec_utils'
require 'shared_examples/render_domain_templates'

RSpec.describe Metalware::CommandHelpers::ConfigureCommand do
  TEST_COMMAND_NAME = :testcommand

  # Subclass of `ConfigureCommand` for use in tests, to test it independently
  # of any individual subclass.
  class TestCommand < Metalware::CommandHelpers::ConfigureCommand
    private

    def setup; end

    # Overridden to be three element array with third a valid `configure.yaml`
    # questions section; `BaseCommand` expects command classes to be namespaced
    # by two modules.
    def class_name_parts
      [:some, :namespace, :test]
    end

    def answer_file
      file_path.domain_answers
    end

    def configurator
      Metalware::Configurator.new(
        config: config,
        questions_section: :domain,
        higher_level_answer_files: []
      )
    end
  end

  include_examples :render_domain_templates, TestCommand

  describe 'option handling' do
    before :each do
      SpecUtils.use_mock_genders(self)
      SpecUtils.mock_validate_genders_success(self)
    end

    it 'passes answers through to configurator as hash' do
      FileSystem.test do |fs|
        fs.with_minimal_repo

        answers = { 'question_1' => 'answer_1' }
        expect_any_instance_of(Metalware::Configurator).to receive(:configure).with(answers)

        Metalware::Utils.run_command(TestCommand, answers: answers.to_json)
      end
    end
  end
end
