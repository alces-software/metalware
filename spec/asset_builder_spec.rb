# frozen_string_literal: true

require 'spec_utils'
require 'asset_builder'
require 'alces_utils'

RSpec.shared_examples 'pushes the asset' do
  it 'pushes the asset onto the stack' do
    expect(subject.stack.last.name).to eq(pushed_asset_name)
    expect(subject.stack.last.source_path).to eq(pushed_source_path)
    expect(subject.stack.last.type).to eq(type)
  end
end

RSpec.describe Metalware::AssetBuilder do
  include AlcesUtils

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
      let(:pushed_asset_name) { test_asset }
      let(:pushed_source_path) { type_path }

      include_examples 'pushes the asset'
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

        let(:pushed_asset_name) { layout_asset }
        let(:pushed_source_path) { layout_path }

        include_examples 'pushes the asset'
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

    it 'does not return assets that already exist' do
      push_test_asset
      AlcesUtils.mock(self) { create_asset(test_asset, {}, type: type) }
      expect(subject.pop_asset).to be_nil
    end
  end

  shared_examples 'save asset methods' do
    let(:asset) { subject.pop_asset }
    let(:source_content) { Metalware::Data.load(asset.source_path) }

    before { FileSystem.root_setup(&:with_asset_types) }

    context 'with the test asset' do
      before { push_test_asset }

      it 'saves the asset' do
        run_save.call
        content = alces.assets.find_by_name(test_asset).to_h.tap do |c|
          c.delete(:metadata)
        end
        expect(content).to eq(source_content)
      end

      it 'errors if the file is invalid' do
        allow(Metalware::Data).to receive(:load).and_return([])
        expect do
          run_save.call
        end.to raise_error(Metalware::ValidationFailure)
      end
    end

    context 'with a sub asset layout' do
      let(:parent_type) { 'rack' }
      let(:layout_name) { 'rack1-layout' }
      let(:layout_content) do
        content_generator('server^server1', 'pdu^pdu1')
      end
      let(:asset_name) { 'rack1' }
      let(:asset_content) do
        alces.assets.find_by_name(asset_name).to_h.tap do |data|
          data.delete(:metadata)
        end
      end
      let(:sub_asset_names) do
        ["#{asset_name}-server1", "#{asset_name}-pdu1"]
      end
      let(:expected_asset_content) do
        links = sub_asset_names.map { |n| '^' + n }
        content_generator(links[0], links[1])
      end

      def content_generator(server_value, pdu_value)
        {
          'no_double_^': 'does-not^replace-double^chevron',
          server: server_value,
          some_key: {
            pdus: ['^pdu-existing-asset-do-not-touch', pdu_value],
          },
        }
      end

      AlcesUtils.mock(self, :each) do
        create_layout(layout_name, layout_content, type: parent_type)
        subject.push_asset(asset_name, layout_name)
        run_save.call
      end

      it 'transforms the sub asset notation to asset names' do
        expect(asset_content).to eq(expected_asset_content)
      end

      it 'adds the sub assets to stack' do
        stacked_assets = subject.stack.map(&:name)
        expect(stacked_assets).to contain_exactly(*sub_asset_names)
      end
    end
  end

  describe '#save' do
    let(:run_save) { proc { asset.save } }

    include_examples 'save asset methods'
  end

  describe '#edit_and_save' do
    let(:run_save) { proc { asset.edit_and_save } }
    let(:mock_highline) do
      instance_double(HighLine).tap do |h|
        allow(h).to receive(:agree).and_return(false)
      end
    end

    before do
      allow(HighLine).to receive(:new).and_return(mock_highline)
      allow(Metalware::Utils::Editor).to receive(:open)
    end

    include_examples 'save asset methods'
  end

  describe '#edit_asset' do
    let(:path) { Metalware::Records::Asset.path(test_asset) }
    let(:expected_content) { { key: 'content' } }

    AlcesUtils.mock(self, :each) do
      FileSystem.root_setup(&:with_minimal_repo)
      create_asset(test_asset, {}, type: type)
    end

    it 'calls the asset to edited and saved' do
      allow(Metalware::Utils::Editor).to receive(:open).and_wrap_original do |_, path|
        Metalware::Data.dump(path, expected_content)
      end
      subject.edit_asset(test_asset)
      expect(alces.assets.find_by_name(test_asset).to_h).to include(expected_content)
    end
  end
end
