# frozen_string_literal: true

require 'cache/asset'
require 'filesystem'
require 'commands'
require 'utils'

RSpec.describe Metalware::Commands::Asset::Delete do

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

    let :asset { 'saved-asset' }
    let :asset_path { Metalware::FilePath.asset(asset) }
    let :asset_content { { key: 'value' } }

    before :each { Metalware::Data.dump(asset_path, asset_content) }

    def run_command
      Metalware::Utils.run_command(described_class,
                                   asset,
                                   stderr: StringIO.new)
    end
    
    it 'deletes the asset file' do
      run_command
      expect(File.exist?(asset_path)).to eq(false)
    end
  end
end
