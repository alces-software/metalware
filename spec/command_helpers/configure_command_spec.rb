
# frozen_string_literal: true

require 'filesystem'
require 'spec_utils'

RSpec.describe Metalware::CommandHelpers::ConfigureCommand do
  TEST_COMMAND_NAME = :testcommand

  # Subclass of `ConfigureCommand` for use in tests, to test it independently
  # of any individual subclass.
  class TestCommand < Metalware::CommandHelpers::ConfigureCommand
    private

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
      Metalware::Configurator.new(alces, questions_section: :domain)
    end
  end

  describe 'option handling' do
    before do
      use_mock_genders
      mock_validate_genders_success
    end

    it 'passes answers through to configurator as hash' do
      FileSystem.test do |fs|
        fs.with_minimal_repo

        answers = { question_1: 'answer_1' }
        expect_any_instance_of(Metalware::Configurator)
          .to receive(:configure).with(answers)

        Metalware::Utils.run_command(TestCommand, answers: answers.to_json)
      end
    end
  end
end
