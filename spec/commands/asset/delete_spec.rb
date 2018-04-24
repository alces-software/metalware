# frozen_string_literal: true

require 'cache/asset'
require 'filesystem'
require 'commands'
require 'utils'

RSpec.describe Metalware::Commands::Asset::Delete do
  let(:asset) { 'saved-asset' }

  def run_command
    Metalware::Utils.run_command(described_class,
                                 asset,
                                 stderr: StringIO.new)
  end

  it 'errors if the asset does not exist' do
    expect do
      run_command
    end.to raise_error(Metalware::InvalidInput)
  end

  context 'when using a saved asset' do
    before do
      FileSystem.root_setup(&:with_minimal_repo)
    end

    let(:asset_path) { Metalware::Records::Path.asset(asset) }
    let(:asset_content) { { key: 'value' } }

    before { Metalware::Data.dump(asset_path, asset_content) }

    it 'deletes the asset file' do
      run_command
      expect(File.exist?(asset_path)).to eq(false)
    end
  end
end
