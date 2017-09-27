
# frozen_string_literal: true

require 'hash_mergers'
require 'config'
require 'filesystem'
require 'namespaces/alces'

RSpec.describe Metalware::HashMergers::MetalRecursiveOpenStruct do
  let :config { Metalware::Config.new }
  let :alces do
    namespace = Metalware::Namespaces::Alces.new(config)
    allow(namespace).to receive(:answer).and_return(build_answer(namespace))
    namespace
  end

  let :struct { build_answer(alces) }

  def build_answer(alces_input)
    Metalware::HashMergers::MetalRecursiveOpenStruct.new(alces: alces_input,
                                                         key: 'value',
                                                         erb1: '<%= alces.answer.key %>',
                                                         erb2: '<%= alces.answer.erb1 %>',
                                                         erb3: '<%= alces.answer.erb2 %>',
                                                         erb4: '<%= alces.answer.erb3 %>')
  end

  ##
  # The alces namespace is only required for templating purposes, otherwise
  # Hence it should be removed from the hash
  #
  it "doesn't load the alces namespace into the hash" do
    expect(struct.alces).to be_nil
  end

  it 'does a single ERB replacement' do
    expect(struct.erb1).to eq('value')
  end

  it 'can replace multiple embedded erb' do
    expect(struct.erb4).to eq('value')
  end
end
