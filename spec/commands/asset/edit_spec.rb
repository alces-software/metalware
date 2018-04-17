# frozen_string_literal: true

require 'commands'
require 'utils'
require 'filesystem'
require 'shared_examples/asset_command_that_assigns_a_node'

RSpec.describe Metalware::Commands::Asset::Edit do
  before { allow(Metalware::Utils::Editor).to receive(:open) }

  it 'errors if the asset doesnt exist' do
    expect do
      Metalware::Utils.run_command(described_class,
                                   'missing-type',
                                   'name',
                                   stderr: StringIO.new)
    end.to raise_error(Metalware::InvalidInput)
  end

  context 'when using a saved asset' do
    before do
      FileSystem.root_setup(&:with_minimal_repo)
    end

    let(:saved_asset) { 'saved-asset' }
    let(:asset_path) { Metalware::FilePath.asset(saved_asset) }
    let(:test_content) { { key: 'value' } }

    before { Metalware::Data.dump(asset_path, test_content) }

    def run_command
      Metalware::Utils.run_command(described_class,
                                   saved_asset,
                                   stderr: StringIO.new)
    end

    it 'calls for the saved asset to be opened and copied into a temp file' do
      expect(Metalware::Utils::Editor).to receive(:open_copy)
        .with(asset_path, asset_path)
      run_command
    end
  end

  context 'with a node input' do
    let(:asset_name) { 'asset1' }
    let(:command_arguments) { [asset_name] }

    before do
      Metalware::Data.dump(Metalware::FilePath.asset(asset_name), {})
    end

    it_behaves_like 'asset command that assigns a node'
  end
end
