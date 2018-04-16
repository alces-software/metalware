# frozen_string_literal: true

require 'alces_utils'
require 'namespaces/alces'

RSpec.describe Metalware::Namespaces::Asset do
  include AlcesUtils

  let :metal_ros do
    Metalware::HashMergers::MetalRecursiveOpenStruct
  end

  it 'inherits from MetalROS' do
    expect(described_class).to be < metal_ros
  end

  context 'when it is initialized with a block' do
    let :unrendered_erb { '<%= alces.domain %>' }
    let :data { { key: unrendered_erb } }

    it 'does not error' do
      expect do
        described_class.new({}) { |_s| 'some block' }
      end.not_to raise_error
    end

    it 'does not render strings' do
      asset = described_class.new(data) do |template|
        alces.domain.render_erb_template(template)
      end
      expect(asset.key).to eq(unrendered_erb)
    end
  end

  context 'when referencing other asset (":<asset_name>")' do
    let :asset1 { alces.assets.find_by_name(asset1_name) }
    let :asset2 { alces.assets.find_by_name(asset2_name) }
    let :asset1_name { 'test-asset1' }
    let :asset2_name { 'test-asset2' }
    let :asset1_data do
      {
        key: "#{asset1_name}-data",
        link: ":#{asset2_name}",
      }
    end
    let :asset2_data do
      {
        key: "#{asset2_name}-data",
        link: ":#{asset1_name}",
      }
    end

    AlcesUtils.mock(self, :each) do
      create_asset(asset1_name, asset1_data)
      create_asset(asset2_name, asset2_data)
    end

    it 'can still be converted to a hash' do
      expect(asset1.to_h).to eq(asset1_data)
    end
  end
end
