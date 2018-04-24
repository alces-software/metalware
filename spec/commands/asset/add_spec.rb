# frozen_string_literal: true

require 'commands'
require 'utils'
require 'filesystem'
require 'shared_examples/asset_command_that_assigns_a_node'

RSpec.describe Metalware::Commands::Asset::Add do
  # Stops the editor from running the bash command
  before { allow(Metalware::Utils::Editor).to receive(:open) }

  it 'errors if the type does not exist' do
    expect do
      Metalware::Utils.run_command(described_class,
                                   'missing-type',
                                   'name',
                                   stderr: StringIO.new)
    end.to raise_error(Metalware::InvalidInput)
  end

  context 'when using the default type' do
    before do
      FileSystem.root_setup(&:with_minimal_repo)
    end

    let(:type) { 'default' }
    let(:save) { 'saved-asset' }

    let(:type_path) { Metalware::FilePath.asset_type(type) }
    let(:save_path) { Metalware::FilePath.asset(save) }

    def run_command
      Metalware::Utils.run_command(described_class,
                                   type,
                                   save,
                                   stderr: StringIO.new)
    end

    it 'calls for the type to be opened and copyed' do
      expect(Metalware::Utils::Editor).to receive(:open_copy)
        .with(type_path, save_path)
      run_command
    end

    it 'errors if the asset already exists' do
      run_command
      expect do
        run_command
      end.to raise_error(Metalware::InvalidInput)
    end
  end

  context 'with a node argument' do
    before { FileSystem.root_setup(&:with_minimal_repo) }

    let(:asset_name) { 'asset1' }
    let(:command_arguments) { ['default', asset_name] }

    it_behaves_like 'asset command that assigns a node'
  end
end
