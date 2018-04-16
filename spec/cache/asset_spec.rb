require 'alces_utils'
require 'cache/asset'

RSpec.describe Metalware::Cache::Asset do
  include AlcesUtils
  
  let :cache { Metalware::Cache::Asset.new }
  let :initial_content { { node: { node_name.to_sym => 'asset_test' } } }
  let :node_name { 'test_node' } 
  let :node { alces.nodes.find_by_name(node_name) }

  AlcesUtils.mock(self, :each) do
    mock_node(node_name) 
  end
  
  describe '#data' do
    it 'handles empty cache' do
      expect do
        cache.data
      end.not_to raise_error
    end

    it 'returns populated cache' do
      Metalware::Data.dump(Metalware::FilePath.asset_cache, initial_content)
      expect(cache.data).to eq(initial_content)
    end
  end

  describe '#save' do
    it 'saves the cache to yaml' do
      cache.assign_asset_to_node('asset_test', node)
      cache.save
      new_cache = Metalware::Cache::Asset.new
      expect(new_cache.data).to eq(initial_content)
    end
  end

  describe '#assign_asset_to_node' do
    it 'assigns an asset to a node' do
      expect do
        cache.assign_asset_to_node('asset_test', node)
      end.not_to raise_error
    end 
  end

  describe '#asset_for_node' do
    let :asset_name { 'test-asset' }
    before :each do
      cache.assign_asset_to_node(asset_name, node)
      cache.save
    end

    it 'returns the corresponding nodes asset' do
      expect(cache.asset_for_node(node)).to eq(asset_name)
    end

    it 'returns the asset after the cache has been reloaded' do
      new_cache = Metalware::Cache::Asset.new
      expect(new_cache.asset_for_node(node)).to eq(asset_name)
    end
  end

  describe '#unassign_asset' do
    let :asset_name { 'asset_test' }
    let :expected_content { { node: {} } }
    before :each do
      cache.assign_asset_to_node(asset_name, node)
      cache.save
    end

    it 'unassigns the asset from all found instances ' do
      cache.unassign_asset(asset_name)
      cache.save
      new_cache = Metalware::Cache::Asset.new
      expect(new_cache.data).to eq(expected_content)
    end

    it 'unassigns an asset from a specific node' do
      cache.unassign_asset(asset_name, node_name)
      cache.save
      new_cache = Metalware::Cache::Asset.new
      expect(new_cache.data).to eq(expected_content)
    end

    it 'attempts to unassign a missing asset' do
      cache.unassign_asset('missing_asset')
      new_cache = Metalware::Cache::Asset.new
      expect(new_cache.data).to eq(initial_content) 
    end
  end
end
