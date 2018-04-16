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
    it 'does not error' do
      expect do
        described_class.new({}) { |_s| 'some block' }
      end.not_to raise_error
    end
  end
end
