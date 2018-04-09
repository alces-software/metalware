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

    describe '#[]' do
      it 'loads the date' do
        expect(subject[index]).to eq(asset[:data])
      end

      it 'only loads the asset file once' do
        expect(Metalware::Data).to receive(:load).once.and_call_original
        subject[index]
        subject[index]
      end
    end

    describe 'asset name method' do
      it 'can load the asset by name' do
        expect(subject.send(asset[:name])).to eq(asset[:data])
      end
    end
  end

  describe 'each' do
    it 'loops through all the asset data' do
      asset_data = assets.map { |a| a[:data] }
      expect(subject.each.to_a).to eq(asset_data)
    end
  end
end

