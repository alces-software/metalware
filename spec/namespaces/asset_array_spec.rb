# frozen_string_literal: true

require 'alces_utils'
require 'namespaces/alces'

RSpec.describe Metalware::Namespaces::AssetArray do
  subject { described_class.new(alces_copy) }

  # DO NOT use AlcesUtils in the section. It tests features required
  # by the namespace itself.
  let(:alces_copy) { Metalware::Namespaces::Alces.new }
  let(:assets) do
    [
      {
        name: 'asset1',
        types_dir: 'pdus',
        data: { key: 'value1' },
      },
      {
        name: 'asset2',
        types_dir: 'racks',
        data: { key: 'value2' },
      },
    ]
  end

  let(:assets_data) do
    assets.map do |asset|
      asset[:data].merge(metadata: { name: asset[:name] })
    end
  end

  let(:metal_ros) do
    Metalware::HashMergers::MetalRecursiveOpenStruct
  end

  before do
    assets.each do |asset|
      path = Metalware::FilePath.asset(asset[:types_dir],
                                       asset[:name])
      FileUtils.mkdir_p(File.dirname(path))
      Metalware::Data.dump(path, asset[:data])
    end
  end

  describe '#new' do
    context 'when there is an asset called "each"' do
      before do
        each_path = Metalware::FilePath.asset('racks', 'each')
        FileUtils.mkdir_p(File.dirname(each_path))
        Metalware::Data.dump(each_path, data: 'some-data')
      end

      it 'errors due to the existing method' do
        expect do
          described_class.new(alces_copy)
        end.to raise_error(Metalware::DataError)
      end
    end

    it 'does not load the files when initially called' do
      expect(Metalware::Data).not_to receive(:load)
      described_class.new(alces_copy)
    end
  end

  context 'when loading the second asset' do
    let(:index) { 1 }
    let(:asset) { assets[index] }
    let(:asset_data) { assets_data[index] }

    def expect_to_only_load_asset_data_once
      expect(Metalware::Data).to receive(:load).once.and_call_original
    end

    describe '#[]' do
      it 'loads the date' do
        expect(subject[index].to_h).to eq(asset_data)
      end

      it 'only loads the asset file once' do
        expect_to_only_load_asset_data_once
        subject[index]
        subject[index]
      end

      it 'returns a MetalRecursiveOpenStruct' do
        expect(subject[index]).to be_a(metal_ros)
      end
    end

    describe '#find_by_name' do
      it 'returns the asset' do
        expect(subject.find_by_name(asset[:name]).to_h).to \
          eq(asset_data)
      end

      it 'only loads the asset data once' do
        expect_to_only_load_asset_data_once
        subject.find_by_name(asset[:name])
        subject.find_by_name(asset[:name])
      end

      it 'returns nil if the asset is missing' do
        expect(subject.find_by_name('missing-asset')).to eq(nil)
      end
    end
  end

  describe 'each' do
    it 'loops through all the asset data' do
      expect(subject.each.to_a.map(&:to_h)).to eq(assets_data)
    end

    context 'when called without a block' do
      it 'returns an enumerator' do
        expect(subject.each).to be_a(Enumerator)
      end
    end

    context 'when called with a block' do
      it 'runs the block' do
        expect do |b|
          subject.map(&:to_h).each(&b)
        end.to yield_successive_args(*assets_data)
      end
    end
  end

  context 'when referencing other asset ("^<asset_name>")' do
    include AlcesUtils

    let(:asset1) { alces.assets.find_by_name(asset1_name) }
    let(:asset2) { alces.assets.find_by_name(asset2_name) }
    let(:asset1_name) { 'test-asset1' }
    let(:asset2_name) { 'test-asset2' }
    let(:asset1_raw_data) do
      {
        key: "#{asset1_name}-data",
        link: "^#{asset2_name}",
      }
    end
    let(:asset2_raw_data) do
      {
        key: "#{asset2_name}-data",
        link: "^#{asset1_name}",
      }
    end

    AlcesUtils.mock(self, :each) do
      create_asset(asset1_name, asset1_raw_data)
      create_asset(asset2_name, asset2_raw_data)
    end

    it 'can still be converted to a hash' do
      expect(asset1.to_h).to include(**asset1_raw_data)
    end

    it 'can find the referenced asset' do
      expect(asset1.link).to eq(asset2)
    end

    it 'only converts strings starting with "^" to an assets' do
      expect(asset1.key).to eq(asset1_raw_data[:key])
    end
  end
end
