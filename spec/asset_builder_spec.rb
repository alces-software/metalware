# frozen_string_literal: true

require 'spec_utils'
require 'asset_builder'

RSpec.describe Metalware::AssetBuilder do
  subject { described_class.new }

  describe '#queue' do
    it 'initially returns an empty array' do
      expect(subject.queue).to eq([])
    end
  end

  describe '#push_asset' do
    let(:type_asset) { 'type-asset-name' }
    let(:type) { 'rack' }

    before { subject.push_asset(type_asset, type) }

    context 'when adding an asset from a type' do
      it 'pushes the asset onto the queue' do
        expect(subject.queue.last.name).to eq(type_asset)
        expect(subject.queue.last.layout).to eq(type)
      end
    end

    context 'when adding an asset from a layout' do
      let(:layout) { 'new-layout' }
      let(:layout_asset) { 'layout-asset-name' }
      let(:layout_path) { Metalware::FilePath.layout(type, layout) }

      def push_layout_asset
        subject.push_asset(layout_asset, layout)
      end

      it 'pushes the asset if the layout exists' do
        FileUtils.mkdir_p(File.dirname(layout_path))
        Metalware::Data.dump(layout_path, {})
        push_layout_asset
        expect(subject.queue.last.name).to eq(layout_asset)
      end
    end
  end
end
