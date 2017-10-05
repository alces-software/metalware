
# frozen_string_literal: true

require 'namespaces/alces'
require 'config'
require 'constants'
require 'nodeattr_interface'

RSpec.describe Metalware::Namespaces::Nodes do
  let :config { Metalware::Config.new }
  let :alces { Metalware::Namespaces::Alces.new(config) }

  let :node_names { ['node1', 'node2', 'node3'] }

  before :each do
    allow(Metalware::NodeattrInterface).to \
      receive(:all_nodes).and_return(node_names)
  end

  it 'has the correct number of nodes' do
    expect(alces.nodes.length).to eq(node_names.length)
  end

  it 'can find all the nodes' do
    node_names.each do |node|
      found_node = alces.nodes.send(node)
      expect(found_node.name).to eq(node)
    end
  end

  it 'can not be modified' do
    expect do
      alces.nodes.push('I should error')
    end.to raise_error(RuntimeError)
  end
end
