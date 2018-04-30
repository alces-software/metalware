# frozen_string_literal: true

require 'spec_utils'
require 'asset_builder'

RSpec.describe Metalware::AssetBuilder do
  subject { described_class.new }

  let(:type_asset) { 'type-asset-name' }
  let(:type) { 'rack' }
  let(:type_path) { Metalware::FilePath.asset_type(type) }

  def push_type_asset
    subject.push_asset(type_asset, type)
  end

  describe '#queue' do
    it 'initially returns an empty array' do
      expect(subject.queue).to eq([])
    end
  end

  describe '#push_asset' do
    before do
      SpecUtils.enable_output_to_stderr
      push_type_asset
    end

    context 'when adding an asset from a type' do
      it 'pushes the asset onto the queue' do
        expect(subject.queue.last.name).to eq(type_asset)
        expect(subject.queue.last.source_path).to eq(type_path)
        expect(subject.queue.last.type).to eq(type)
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
          expect(subject.queue.last.name).to eq(layout_asset)
          expect(subject.queue.last.source_path).to eq(layout_path)
          expect(subject.queue.last.type).to eq(type)
        end
      end

      it 'warns and does nothing if the layout does not exist' do
        original_queue = subject.queue.dup
        expect do
          push_layout_asset
        end.to output(/Failed to add asset: "#{layout_asset}"/).to_stderr
        expect(subject.queue).to eq(original_queue)
      end
    end
  end

  describe '#empty?' do
    it 'returns true when the queue is empty' do
      expect(subject.empty?).to be true
    end

    it 'returns false when there is an asset on the queue' do
      push_type_asset
      expect(subject.empty?).to be false
    end
  end
end
