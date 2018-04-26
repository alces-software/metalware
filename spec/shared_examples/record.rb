# frozen_string_literal: true

require 'spec_utils'

RSpec.shared_examples 'record' do
  let(:asset_hash) do
    {
      pdus: ['pdu1', 'pdu2'],
      racks: ['rack1', 'rack2'],
    }
  end

  let(:legacy_assets) { ['legacy1', 'legacy2'] }

  let(:assets) do
    asset_hash.reduce(legacy_assets) do |memo, (_k, name)|
      memo.dup.concat(name)
    end
  end

  # Creates the asset files
  before do
    paths = []
    asset_hash.each do |types_dir, names|
      names.each do |name|
        paths << Metalware::FilePath.asset(types_dir.to_s, name)
      end
    end
    legacy_assets.each do |legacy|
      paths << File.expand_path(Metalware::FilePath.asset('.', legacy))
    end
    paths.each do |path|
      FileUtils.mkdir_p(File.dirname(path))
      FileUtils.touch(path)
    end
  end

  describe '#path' do
    it 'can not find a legacy assets' do
      expect(described_class.path(legacy_assets.last)).to eq(nil)
    end

    context 'with an asset within a type directory' do
      let(:types_dir) { asset_hash.keys.last }
      let(:name) { asset_hash[types_dir].last }
      let(:expected_path) do
        Metalware::FilePath.asset(types_dir.to_s, name)
      end

      it 'finds the asset' do
        expect(described_class.path(name)).to eq(expected_path)
      end

      it 'finds the asset with the missing_error flag' do
        path = described_class.path(name, missing_error: true)
        expect(path).to eq(expected_path)
      end
    end

    context 'with a missing asset' do
      let(:missing) { 'missing-asset' }

      it 'returns nil by default' do
        expect(described_class.path(missing)).to eq(nil)
      end

      it 'errors with the missing_error flag' do
        expect do
          described_class.path(missing, missing_error: true)
        end.to raise_error(Metalware::MissingRecordError)
      end
    end
  end

  describe '#available?' do
    it 'returns true if the asset is missing' do
      expect(described_class.available?('missing-asset')).to eq(true)
    end

    it 'returns false if the asset exists' do
      name = asset_hash.values.last.last
      expect(described_class.available?(name)).to eq(false)
    end

    { 'public' => 'each', 'private' => 'alces' }.each do |type, method|
      it "returns false for #{type} methods on AssetArray" do
        expect(described_class.available?(method)).to eq(false)
      end
    end

    context 'when using a reserved type name' do
      let(:type) { 'rack' }

      it 'returns false' do
        expect(described_class.available?(type)).to eq(false)
      end

      it 'is false for the plural' do
        expect(described_class.available?(type.pluralize)).to eq(false)
      end
    end
  end
end
