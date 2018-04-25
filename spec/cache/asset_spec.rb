# frozen_string_literal: true

require 'alces_utils'
require 'cache/asset'

RSpec.describe Metalware::Cache::Asset do
  include AlcesUtils

  def update(&b)
    described_class.update(&b)
  end

  let(:cache) { described_class.new }
  let(:cache_path) { Metalware::FilePath.asset_cache }
  let(:initial_content) do
    { node: { node_name.to_sym => 'asset_test' } }
  end
  let(:node_name) { 'test_node' }
  let(:node) { alces.nodes.find_by_name(node_name) }

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
      Metalware::Data.dump(cache_path, initial_content)
      expect(cache.data).to eq(initial_content)
    end
  end

  describe '#save' do
    it 'saves the cache to yaml' do
      cache.assign_asset_to_node('asset_test', node)
      cache.save
      new_cache = described_class.new
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
    let(:asset_name) { 'test-asset' }

    before do
      cache.assign_asset_to_node(asset_name, node)
      cache.save
    end

    it 'returns the corresponding nodes asset' do
      expect(cache.asset_for_node(node)).to eq(asset_name)
    end

    it 'returns the asset after the cache has been reloaded' do
      new_cache = described_class.new
      expect(new_cache.asset_for_node(node)).to eq(asset_name)
    end
  end

  describe '#unassign_asset' do
    let(:asset_name) { 'asset_test' }
    let(:expected_content) { { node: {} } }

    before do
      cache.assign_asset_to_node(asset_name, node)
      cache.save
    end

    context 'with multiple assets in cache' do
      let(:initial_content) do
        node_data = expected_content[:node].merge(
          node_name.to_sym => asset_name,
          node02: asset_name
        )
        { node: node_data }
      end

      let(:expected_content) do
        {
          node: {
            node01: 'test-asset-01',
            node03: 'test-asset-03',
          },
        }
      end

      before do
        Metalware::Data.dump(cache_path, initial_content)
      end

      it 'unassigns the asset from all found instances ' do
        cache = described_class.new
        cache.unassign_asset(asset_name)
        cache.save
        new_cache = described_class.new
        expect(new_cache.data).to eq(expected_content)
      end
    end

    it 'unassigns an asset from the cache' do
      cache.unassign_asset(asset_name)
      cache.save
      new_cache = described_class.new
      expect(new_cache.data).to eq(expected_content)
    end

    it 'unassigns a node from the cache' do
      cache.unassign_node(node_name)
      cache.save
      new_cache = described_class.new
      expect(new_cache.data).to eq(expected_content)
    end

    it 'attempts to unassign a missing asset' do
      cache.unassign_asset('missing_asset')
      new_cache = described_class.new
      expect(new_cache.data).to eq(initial_content)
    end
  end

  describe '#update' do
    it 'ensures it saves the cache after an error' do
      expect do
        update do |cache|
          cache.assign_asset_to_node('asset_test', node)
          raise RuntimeError
        end
      end.to raise_error(RuntimeError)
      expect(cache.data).to eq(initial_content)
    end

    it 'updates the cache' do
      update do |cache|
        cache.assign_asset_to_node('asset_test', node)
      end
      expect(cache.data).to eq(initial_content)
    end
  end
end
