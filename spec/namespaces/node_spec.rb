
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
    allow(a).to receive(:groups).and_return(
      Metalware::Namespaces::MetalArray.new(
        [
          Metalware::Namespaces::Group
            .new(a, 'primary_group', index: primary_group_index),
        ]
      )
    )
    a
  end

  def build_groups_hash(node_array)
    node_array.each_with_object({}) do |name, memo|
      memo[name.to_sym] = { name: name }
    end
  end

  def return_node_at_runtime
    node
  end

  let :test_value { 'test value set in namespace/node_spec.rb' }
  let :primary_group_index { 'primary_group_index' }
  let :node_name { 'node02' }
  let :node_array { ['some_other_node', node_name] }

  ##
  # Mocking the HashMerger to return a specified hash as the original
  # block should still be used. It has been mocked by specifying a new
  # block that references the original render_node_template block contained
  # within Namespaces::Node
  #
  let :config_hash do
    Metalware::Constants::HASH_MERGER_DATA_STRUCTURE.new(
      key: test_value,
      erb_value1: '<%= alces.node.config.key  %>'
    ) { |template_string| render_node_template(template_string) }
  end

  def render_node_template(template)
    template_lambda = node.send(:template_block)
    template_lambda.call(template)
  end

  let :node { Metalware::Namespaces::Node.new(alces, node_name) }

  ##
  # Mocks the HashMergers
  #
  before :each do
    allow(Metalware::HashMergers::Config).to receive(:new)
      .and_return(double('config', merge: config_hash))
    allow(Metalware::HashMergers::Answer).to receive(:new)
      .and_return(double('answer', merge: {}))
  end

  ##
  # Spoofs the results of NodeattrInterface
  #
  before :each do
    allow(Metalware::NodeattrInterface).to \
      receive(:groups_for_node).and_return(['primary_group'])
    allow(Metalware::NodeattrInterface).to \
      receive(:nodes_in_group).and_return(node_array)
    allow(Metalware::NodeattrInterface).to \
      receive(:all_nodes).and_return(node_array)
  end

  it 'can access the node name' do
    expect(node.name).to eq(node_name)
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

  it 'can determine the node index' do
    expect(node.index).to eq(2)
  end

  describe '#==' do
    let :foonode { Metalware::Namespaces::Node.new(alces, 'foonode') }
    let :barnode { Metalware::Namespaces::Node.new(alces, 'barnode') }

    it 'returns false if other object is not a Node' do
      other_object = Struct.new(:name).new('foonode')
      expect(foonode).not_to eq(other_object)
    end

    it 'defines nodes with the same name as equal' do
      expect(foonode).to eq(foonode)
    end

    it 'defines nodes with different names as not equal' do
      expect(foonode).not_to eq(barnode)
    end
  end
end
