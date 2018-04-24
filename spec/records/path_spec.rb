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
  before :each do
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

  it 'can find an asset within a type directory' do
    type = asset_hash.keys.last
    name = asset_hash[type].last
    path = Metalware::FilePath.asset(File.join(type.to_s, name))
    expect(described_class.asset(name)).to eq(path)
  end

  it 'returns nil if the asset is missing' do
    name = 'missing-asset'
    expect(described_class.asset(name)).to eq(nil)
  end
end
