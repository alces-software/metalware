
require 'alces_utils'
require 'cache/asset'

# Requires `command_arguments` to be set by the calling spec
RSpec.shared_examples 'asset command that assigns a node' do
  include AlcesUtils

  let :asset_cache { Metalware::Cache::Asset.new }

  let :node_name { 'test-node' }
  let! :node { AlcesUtils.mock(self) { mock_node(node_name) } }

  def run_command
    Metalware::Utils.run_command(described_class,
                                 *command_arguments,
                                 node: node_name)
  end

  it 'assigns the asset to the node' do
    run_command
    expect(asset_cache.asset_for_node(node)).to eq(asset_name)
  end
end
