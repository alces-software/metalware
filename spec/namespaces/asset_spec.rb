# frozen_string_literal: true

require 'namespaces/alces'

RSpec.describe Metalware::Namespaces::Asset do
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
end
