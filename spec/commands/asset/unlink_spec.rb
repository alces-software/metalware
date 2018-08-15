# frozen_string_literal: true

require 'filesystem'
require 'alces_utils'

RSpec.describe Metalware::Commands::Asset::Unlink do
  include AlcesUtils

  let(:node_name) { 'test_node' }
  let(:node) { alces.nodes.find_by_name(node_name) }
  let(:content) { { node: { node_name.to_sym => asset_name } } }
  let(:cache) { Metalware::Cache::Asset.new }

  AlcesUtils.mock(self, :each) do
    mock_node(node_name)
  end

  def run_command
    Metalware::Utils.run_command(described_class,
                                 node_name,
                                 stderr: StringIO.new)
  end

  context 'when using a saved asset' do
    before do
      FileSystem.root_setup(&:with_minimal_repo)
    end

    let(:asset_name) { 'asset_test' }
    let(:asset_content) { { key: 'value' } }
    let(:cache_path) { Metalware::FilePath.asset_cache }
    let(:cache_content) do
      { node: { node_name.to_sym => asset_name } }
    end

    AlcesUtils.mock(self, :each) do
      create_asset(asset_name, asset_content)
      Metalware::Data.dump(cache_path, cache_content)
    end

    it 'unlinks the asset from a node' do
      run_command
      new_cache = Metalware::Cache::Asset.new
      expect(new_cache.data).not_to eq(cache_content)
    end
  end

  context 'when using a node that has no relationships' do
    let(:node_name) { 'lonely_node' }

    it 'does not change the cache when attempting to unlink' do
      run_command
      new_cache = Metalware::Cache::Asset.new
      expect(new_cache.data).to eq(cache.data)
    end
  end
end
