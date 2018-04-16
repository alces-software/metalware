# frozen_string_literal: true

require 'namespaces/alces'

RSpec.describe Metalware::Namespaces::Asset do
  let :metal_ros do
    Metalware::HashMergers::MetalRecursiveOpenStruct
  end

  it 'inherits from MetalROS' do
    expect(described_class).to be < metal_ros
  end
end
