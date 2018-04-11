# frozen_string_literal: true

require 'commands'
require 'utils'
require 'filesystem'

RSpec.describe Metalware::Commands::Asset::Edit do
  before :each { allow(Metalware::Utils::Editor).to receive(:open) }

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
      FileSystem.root_setup do |fs|
        fs.with_minimal_repo
      end
    end

    let :saved_asset { 'saved-asset' }
    let :asset_path { Metalware::FilePath.asset(saved_asset) }

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
    
    i
  end
end
