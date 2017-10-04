
# frozen_string_literal: true

require 'namespaces/alces'
require 'config'
require 'constants'
require 'hash_mergers'

RSpec.describe Metalware::Namespaces::Node do
  let :config { Metalware::Config.new }
  let :alces { Metalware::Namespaces::Alces.new(config) }

  let :test_value { 'test value set in namespace/node_spec.rb' }

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
    allow(Metalware::HashMergers).to receive(:merge).and_return(hash_merger)
    namespace = Metalware::Namespaces::Node.new(alces, '_node_name')
    allow(namespace).to receive(:genders).and_return([])
    namespace
  end

  it 'can retreive a simple config value for the node' do
    expect(node.config.key).to eq(test_value)
  end

  it 'config parameters can reference other config parameters' do
    expect(node.config.erb_value1).to eq(test_value)
  end
end
