# frozen_string_literal: true

require 'spec_utils'
require 'records/path'

RSpec.describe Metalware::Records::Path do
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
    all_assets = []
    asset_hash.each do |types_dir, names|
      names.each do |name|
        all_assets << File.join(types_dir.to_s, name)
      end
    end
    legacy_assets.each { |n| all_assets << n }
    all_assets.each do |asset|
      path = Metalware::FilePath.asset(asset)
      FileUtils.mkdir_p(File.dirname(path))
      FileUtils.touch(path)
    end
  end

  # NOTE: Once FilePath is updated, the legacy assets should become
  # invisible
  it 'can find a legacy assets' do
    name = legacy_assets.last
    path = Metalware::FilePath.asset(name)
    expect(described_class.asset(name)).to eq(path)
  end

  context 'with an asset within a type directory' do
    let(:type) { asset_hash.keys.last }
    let(:name) { asset_hash[type].last }
    let(:expected_path) do
      Metalware::FilePath.asset(File.join(type.to_s, name))
    end

    it 'finds the asset' do
      expect(described_class.asset(name)).to eq(expected_path)
    end

    it 'finds the asset with the missing_error flag' do
      path = described_class.asset(name, missing_error: true)
      expect(path).to eq(expected_path)
    end
  end

  context 'with a missing asset' do
    let(:missing) { 'missing-asset' }

    it 'returns nil by default' do
      expect(described_class.asset(missing)).to eq(nil)
    end

    it 'errors with the missing_error flag' do
      expect do
        described_class.asset(missing, missing_error: true)
      end.to raise_error(Metalware::MissingRecordError)
    end
  end
end
