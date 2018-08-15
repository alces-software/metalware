# frozen_string_literal: true

require 'cache/asset'
require 'filesystem'
require 'commands'
require 'utils'
require 'alces_utils'

RSpec.describe Metalware::Commands::Asset::Delete do
  include AlcesUtils
  let(:asset) { 'saved-asset' }

  def run_command
    Metalware::Utils.run_command(described_class,
                                 asset,
                                 stderr: StringIO.new)
  end

  it 'errors if the asset does not exist' do
    expect do
      run_command
    end.to raise_error(Metalware::MissingRecordError)
  end

  context 'when using a saved asset' do
    AlcesUtils.mock(self, :each) do
      FileSystem.root_setup(&:with_minimal_repo)
      create_asset(asset, {})
    end

    it 'deletes the asset file' do
      run_command
      expect(Metalware::Records::Asset.path(asset)).to be_nil
    end
  end
end
