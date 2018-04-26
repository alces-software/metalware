# frozen_string_literal: true

require 'commands'
require 'utils'
require 'filesystem'
require 'shared_examples/asset_command_that_assigns_a_node'
require 'alces_utils'

RSpec.describe Metalware::Commands::Asset::Edit do
  include AlcesUtils
  before { allow(Metalware::Utils::Editor).to receive(:open) }

  it 'errors if the asset doesnt exist' do
    expect do
      Metalware::Utils.run_command(described_class,
                                   'missing-type',
                                   'name',
                                   stderr: StringIO.new)
    end.to raise_error(Metalware::MissingRecordError)
  end

  context 'when using a saved asset' do
    let(:saved_asset) { 'saved-asset' }
    let(:test_content) { { key: 'value' } }
    let(:asset_path) { Metalware::Records::Asset.path(saved_asset) }

    AlcesUtils.mock(self, :each) do
      FileSystem.root_setup(&:with_minimal_repo)
      create_asset(saved_asset, test_content)
    end

    def run_command
      Metalware::Utils.run_command(described_class,
                                   saved_asset,
                                   stderr: StringIO.new)
    end

    it 'calls for the saved asset to be opened and copied into a temp file' do
      expect(Metalware::Utils::Editor).to \
        receive(:open_copy).with(asset_path, asset_path)
      run_command
    end
  end

  context 'with a node input' do
    let(:asset_name) { 'asset1' }
    let(:command_arguments) { [asset_name] }

    AlcesUtils.mock(self, :each) do
      create_asset(asset_name, {})
    end

    it_behaves_like 'asset command that assigns a node'
  end
end
