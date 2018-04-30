# frozen_string_literal: true

require 'alces_utils'
require 'shared_examples/record_edit_command'

RSpec.describe Metalware::Commands::Layout::Edit do
  include AlcesUtils
  before { allow(Metalware::Utils::Editor).to receive(:open) }

  let(:record_name) { 'layout' }
  let(:record_path) { Metalware::Records::Layout.path(record_name) }

  AlcesUtils.mock(self, :each) do
    FileSystem.root_setup(&:with_minimal_repo)
    create_layout(record_name, {})
  end

  it_behaves_like 'record edit command'
end
