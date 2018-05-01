# frozen_string_literal: true

require 'commands'
require 'utils'
require 'filesystem'
require 'shared_examples/asset_command_that_assigns_a_node'
require 'shared_examples/record_edit_command'
require 'alces_utils'

RSpec.describe Metalware::Commands::Asset::Edit do
  include AlcesUtils
  before { allow(Metalware::Utils::Editor).to receive(:open) }

  let(:record_name) { 'asset' }
  let(:record_path) { Metalware::Records::Asset.path(record_name) }

  AlcesUtils.mock(self, :each) do
    FileSystem.root_setup(&:with_minimal_repo)
    create_asset(record_name, {})
  end

  it_behaves_like 'record edit command'

  context 'with a node input' do
    let(:asset_name) { 'asset1' }
    let(:command_arguments) { [asset_name] }

    AlcesUtils.mock(self, :each) do
      create_asset(asset_name, {})
    end
    it_behaves_like 'asset command that assigns a node'
  end
end
