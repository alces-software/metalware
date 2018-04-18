# frozen_string_literal: true

require 'filesystem'
require 'alces_utils'

RSpec.describe Metalware::Commands::Asset::Unlink do
  include AlcesUtils

  let(:asset_name) { 'asset_test' }
  let(:node_name) { 'test_node' }
  let(:node) { alces.nodes.find_by_name(node_name) }
  let(:content) { { node: { node_name.to_sym => asset_name } } }

  AlcesUtils.mock(self, :each) do
    mock_node(node_name)
  end

  def run_command
    Metalware::Utils.run_command(described_class,
                                 asset_name,
                                 node_name,
                                 stderr: StringIO.new)
  end

  it 'error when the asset does not exist' do
    expect do
      run_command
    end.to raise_error(Metalware::InvalidInput)
  end

  context 'when using a saved asset' do
    before do
      FileSystem.root_setup(&:with_minimal_repo)
    end

    let(:asset_path) { Metalware::FilePath.asset(asset_name) }
    let(:asset_content) { { key: 'value' } }
    let(:cache_content) { { node: { node_name.to_sym => asset_name } } }

    before :each do 
      Metalware::Data.dump(asset_path, asset_content)
      Metalware::Data.dump(Metalware::FilePath.asset_cache, cache_content)
    end

    it 'unlinks the asset from a node' do
      run_command
      cache = Metalware::Cache::Asset.new
      expect(cache.data).not_to eq(cache_content)
    end
  end
end
