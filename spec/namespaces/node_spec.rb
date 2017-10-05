
# frozen_string_literal: true

require 'namespaces/alces'
require 'config'
require 'constants'
require 'hash_mergers'
require 'recursive_open_struct'

RSpec.describe Metalware::Namespaces::Node do
  let :config { Metalware::Config.new }
  let :alces do
    a = Metalware::Namespaces::Alces.new(config)
    allow(a).to receive(:groups).and_return(RecursiveOpenStruct.new({
      primary_group: { index: primary_group_index }
    }))
    a
  end

  let :test_value { 'test value set in namespace/node_spec.rb' }
  let :primary_group_index { 'primary_group_index' }

  ##
  # Mocking the HashMerger to return a specified hash as the original
  # block should still be used. It has been mocked by specifying a new
  # block that references the original render_node_template block contained
  # within Namespaces::Node
  #
  let :hash_merger { OpenStruct.new(config: config_hash) }
  let :config_hash do
    Metalware::Constants::HASH_MERGER_DATA_STRUCTURE.new(
      key: test_value,
      erb_value1: '<%= alces.node.config.key  %>'
    ) { |template_string| render_node_template(template_string) }
  end

  def render_node_template(template)
    node.send(:render_erb_template, template)
  end

  let :node do
    allow(Metalware::HashMergers).to \
      receive(:merge).and_return(hash_merger)
    Metalware::Namespaces::Node.new(alces, '_node_name')
  end

  before :each do
    allow(Metalware::NodeattrInterface).to \
      receive(:groups_for_node).and_return(['primary_group'])
  end

  it 'can retreive a simple config value for the node' do
    expect(node.config.key).to eq(test_value)
  end

  it 'config parameters can reference other config parameters' do
    expect(node.config.erb_value1).to eq(test_value)
  end

  it 'can find its group index' do
    expect(node.group.index).to eq(primary_group_index)
  end
end
