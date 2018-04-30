# frozen_string_literal: true

require 'alces_utils'

RSpec.describe Metalware::Commands::Layout::Edit do
  include AlcesUtils
  before { allow(Metalware::Utils::Editor).to receive(:open) }

  it 'errors if the asset doesnt exist' do
    expect do
      Metalware::Utils.run_command(described_class,
                                   'missing-layout',
                                   stderr: StringIO.new)
    end.to raise_error(Metalware::MissingRecordError)
  end

  context 'when using a saved layout' do
    let(:saved_layout) { 'saved-layout' }
    let(:test_content) { { key: 'value' } }
    let(:layout_path) { Metalware::Records::Layout.path(saved_layout) }

    AlcesUtils.mock(self, :each) do
      FileSystem.root_setup(&:with_minimal_repo)
      create_layout(saved_layout, test_content)
    end

    def run_command
      Metalware::Utils.run_command(described_class,
                                   saved_layout,
                                   stderr: StringIO.new)
    end

    it 'calls for the saved layout to be opened and copied' do
      expect(Metalware::Utils::Editor).to receive(:open_copy)
        .with(layout_path, layout_path)
      run_command
    end
  end
end
