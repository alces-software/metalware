# frozen_string_literal: true

require 'shared_examples/asset_command_that_assigns_a_node'
require 'shared_examples/record_add_command'

RSpec.describe Metalware::Commands::Asset::Add do
  let(:record_path) do
    Metalware::FilePath.asset(type.pluralize, saved_record_name)
  end

  it_behaves_like 'record add command'

  context 'with a node argument' do
    before { FileSystem.root_setup(&:with_asset_types) }

    let(:asset_name) { 'asset1' }
    let(:command_arguments) { ['rack', asset_name] }

    it_behaves_like 'asset command that assigns a node'
  end
end
