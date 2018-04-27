
# frozen_string_literal: true

require 'alces_utils'
require 'cache/asset'

# Requires `asset_name` and `command_arguments` to be set by the
# calling spec
RSpec.shared_examples 'asset command that assigns a node' do
  include AlcesUtils

  # Stops the editor from running the bash command
  before { allow(Metalware::Utils::Editor).to receive(:open) }

  let(:asset_cache) { Metalware::Cache::Asset.new }
  let(:node_name) { 'test-node' }

  def run_command
    Metalware::Utils.run_command(described_class,
                                 *command_arguments,
                                 node: node_name,
                                 stderr: StringIO.new)
  end

  context 'when the node is missing' do
    it 'raise an invalid input error' do
      expect { run_command }.to raise_error(Metalware::InvalidInput)
    end
  end

  context 'when the node exists' do
    let!(:node) { AlcesUtils.mock(self) { mock_node(node_name) } }

    it 'assigns the asset to the node' do
      run_command
      expect(asset_cache.asset_for_node(node)).to eq(asset_name)
    end
  end
end
