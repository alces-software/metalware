# frozen_string_literal: true

require 'spec_utils'
require 'shared_examples/record'
require 'records/layout'

RSpec.describe Metalware::Records::Layout do
  include AlcesUtils
  before { allow(Metalware::Utils::Editor).to receive(:open) }

  file_path_proc = proc do |types_dir, name|
    Metalware::FilePath.layout(types_dir, name)
  end

  describe '#path_with_types' do
    let(:type) { 'rack' }
    let(:type_path) { Metalware::FilePath.asset_type(type) }

    it 'errors when given an invalid type or layout' do
      expect do
        described_class.path_with_types('clown-fiesta')
      end.to raise_error(Metalware::InvalidInput)
    end

    it 'returns a type path' do
      expect(described_class.path_with_types(type))
        .to eq(type_path)
    end

    context 'with a saved layout' do
      let(:layout) { 'test-layout' }
      let(:layout_path) { Metalware::FilePath.layout(type.pluralize, layout) }

      AlcesUtils.mock(self, :each) do
        FileSystem.root_setup(&:with_asset_types)
        create_layout
      end

      def create_layout
        Metalware::Utils.run_command(Metalware::Commands::Layout::Add,
                                     type,
                                     layout,
                                     stderr: StringIO.new)
      end

      it 'returns a layout path' do
        expect(described_class.path_with_types(layout))
          .to eq(layout_path)
      end
    end
  end

  let(:valid_path) { Metalware::FilePath.layout('rack', 'saved-layout') }
  let(:invalid_path) { Metalware::FilePath.asset('server', 'saved-asset') }

  it_behaves_like 'record', file_path_proc
end
