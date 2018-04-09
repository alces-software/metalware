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
    it 'does not load the files when initially called' do
      expect(Metalware::Data).not_to receive(:load)
      Metalware::Namespaces::AssetArray.new
    end

    it 'it only loads the file when required' do
    end
  end

  describe '#[]' do
    it 'loads the date' do
      expect(subject[1]).to eq(assets[1][:data])
    end

    it 'only loads the asset file once' do
      expect(Metalware::Data).to receive(:load).once.and_call_original
      subject[1]
      subject[1]
    end
  end

  describe 'asset name method' do
    it 'can load the asset by name' do
      asset = assets[1]
      expect(subject.send(asset[:name])).to eq(asset[:data])
    end
  end
end

