
# frozen_string_literal: true

require 'spec_utils'
require 'filesystem'

RSpec.describe Metalware::Commands::Configure::Domain do
  def run_configure_domain
    SpecUtils.run_command(
      Metalware::Commands::Configure::Domain
    )
  end

  let :config { Metalware::Config.new }

  let :filesystem do
    FileSystem.setup(&:with_minimal_repo)
  end

  before :each do
    SpecUtils.mock_validate_genders_success(self)
  end

  it 'creates correct configurator' do
    filesystem.test do
      expect(Metalware::Configurator).to receive(:new).with(
        configure_file: config.configure_file,
        questions_section: :domain,
        answers_file: config.domain_answers_file,
        higher_level_answer_files: []
      ).and_call_original

      run_configure_domain
    end
  end
end
