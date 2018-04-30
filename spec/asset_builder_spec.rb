# frozen_string_literal: true

require 'spec_utils'
require 'asset_builder'

RSpec.describe Metalware::AssetBuilder do
  subject { described_class.new }

  let(:test_asset) { 'type-asset-name' }
  let(:type) { 'rack' }
  let(:type_path) { Metalware::FilePath.asset_type(type) }

  def push_test_asset
    subject.push_asset(test_asset, type)
  end

  describe '#stack' do
    it 'initially returns an empty array' do
      expect(subject.stack).to eq([])
    end
  end

  describe '#push_asset' do
    before do
      SpecUtils.enable_output_to_stderr
      push_test_asset
    end

    context 'when adding an asset from a type' do
      it 'pushes the asset onto the stack' do
        expect(subject.stack.last.name).to eq(test_asset)
        expect(subject.stack.last.source_path).to eq(type_path)
        expect(subject.stack.last.type).to eq(type)
      end
    end

    context 'when adding an asset from a layout' do
      let(:layout) { 'new-layout' }
      let(:layout_asset) { 'layout-asset-name' }
      let(:layout_path) do
        Metalware::FilePath.layout(type.pluralize, layout)
      end

      def push_layout_asset
        subject.push_asset(layout_asset, layout)
      end

      context 'when the layout exists' do
        before do
          FileUtils.mkdir_p(File.dirname(layout_path))
          Metalware::Data.dump(layout_path, {})
          push_layout_asset
        end

        it 'pushes the asset if the layout exists' do
          expect(subject.stack.last.name).to eq(layout_asset)
          expect(subject.stack.last.source_path).to eq(layout_path)
          expect(subject.stack.last.type).to eq(type)
        end
      end

      it 'warns and does nothing if the layout does not exist' do
        original_stack = subject.stack.dup
        expect do
          push_layout_asset
        end.to output(/Failed to add asset: "#{layout_asset}"/).to_stderr
        expect(subject.stack).to eq(original_stack)
      end
    end
  end

  describe '#empty?' do
    it 'returns true when the stack is empty' do
      expect(subject.empty?).to be true
    end

    it 'returns false when there is an asset on the stack' do
      push_test_asset
      expect(subject.empty?).to be false
    end
  end

  describe '#pop_asset' do
    it 'returns nil if there are no more assets' do
      expect(subject.pop_asset).to eq(nil)
    end

    it 'returns the asset to be built' do
      push_test_asset
      expect(subject.pop_asset.name).to eq(test_asset)
    end

    it 'removes the asset from the stack' do
      length = subject.stack.length
      push_test_asset
      subject.pop_asset
      expect(subject.stack.length).to eq(length)
    end

    it 'removes assets in a FIFO order' do
      subject.push_asset(type, 'some-random-other-asset')
      push_test_asset
      expect(subject.pop_asset.name).to eq(test_asset)
    end
  end
end
