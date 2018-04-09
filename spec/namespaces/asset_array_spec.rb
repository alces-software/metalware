# frozen_string_literal: true

require 'namespaces/alces'

RSpec.describe Metalware::Namespaces::AssetArray do
  subject { Metalware::Namespaces::AssetArray.new }

  let :assets do
    [
      {
        name: 'asset1',
        data: { key: 'value1' },
      },
      {
        name: 'asset2',
        data: { key: 'value2' },
      },
    ]
  end

  before :each do
    assets.each do |asset|
      path = Metalware::FilePath.asset(asset[:name])
      Metalware::Data.dump(path, asset[:data])
    end
  end 

  describe '#new' do
    context 'when there is an asset called "each"' do
      before :each do
        each_path = Metalware::FilePath.asset('each')
        Metalware::Data.dump(each_path, { data: 'some-data' })
      end

      it 'errors due to the existing method' do
        expect do
          Metalware::Namespaces::AssetArray.new
        end.to raise_error(Metalware::DataError)
      end
    end

    it 'does not load the files when initially called' do
      expect(Metalware::Data).not_to receive(:load)
      Metalware::Namespaces::AssetArray.new
    end
  end

  context 'when loading the second asset' do
    let :index { 1 }
    let :asset { assets[index] }

    def expect_to_only_load_asset_data_once
      expect(Metalware::Data).to receive(:load).once.and_call_original
    end

    describe '#[]' do
      it 'loads the date' do
        expect(subject[index].to_h).to eq(asset[:data])
      end

      it 'only loads the asset file once' do
        expect_to_only_load_asset_data_once
        subject[index]
        subject[index]
      end

      it 'returns a RecursiveOpenStruct' do
        expect(subject[index]).to be_a(RecursiveOpenStruct)
      end
    end

    describe '#find_by_name' do
      it 'returns the asset' do
        expect(subject.find_by_name(asset[:name]).to_h).to eq(asset[:data])
      end

      it 'only loads the asset data once' do
        expect_to_only_load_asset_data_once
        subject.find_by_name(asset[:name])
        subject.find_by_name(asset[:name])
      end
    end
  end

  describe 'each' do
    it 'loops through all the asset data' do
      asset_data = assets.map { |a| a[:data] }
      expect(subject.each.to_a.map(&:to_h)).to eq(asset_data)
    end
  end
end

