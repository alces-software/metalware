
# frozen_string_literal: true

require 'hash_mergers'
require 'config'
require 'filesystem'

RSpec.describe Metalware::HashMergers::MetalRecursiveOpenStruct do
  let :alces do
    true
  end

  let :struct do
    Metalware::HashMergers::MetalRecursiveOpenStruct.new(alces: alces)
  end

  ##
  # The alces namespace is only required for templating purposes, otherwise 
  # Hence it should be removed from the hash
  #
  it "doesn't load the alces namespace into the hash" do
    expect(struct.alces).to be_nil
  end
end
