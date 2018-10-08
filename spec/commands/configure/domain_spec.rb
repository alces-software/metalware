
# frozen_string_literal: true

require 'spec_utils'
require 'filesystem'

RSpec.describe Metalware::Commands::Configure::Domain do
  def run_configure_domain
    Metalware::Utils.run_command(
      Metalware::Commands::Configure::Domain
    )
  end

  let(:filesystem) do
    FileSystem.setup(&:with_minimal_repo)
  end

  before do
    mock_validate_genders_success
  end

  it 'creates correct configurator' do
    filesystem.test do
      expect(Metalware::Configurator).to receive(:new).with(
        instance_of(Metalware::Namespaces::Alces),
        questions_section: :domain
      ).and_call_original

      run_configure_domain
    end
  end
end
