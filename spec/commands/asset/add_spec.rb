# frozen_string_literal: true

require 'shared_examples/asset_command_that_assigns_a_node'
require 'shared_examples/record_add_command'
require 'alces_utils'

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

  context 'with sub asseting' do
    include AlcesUtils

    let(:mocked_highline) do
      instance_double(HighLine).tap do |highline|
        allow(highline).to receive(:agree).and_return(highline_answer)
      end
    end
    let(:layout_name) { 'my-super-awesome-layout' }
    let(:layout_content) { { key: "pdu^#{sub_asset_name_fragment}" } }
    let(:parent_asset_name) { 'parent-asset' }
    let(:sub_asset_name_fragment) { 'pdu1' }
    let(:sub_asset_name) do
      "#{parent_asset_name}_#{sub_asset_name_fragment}"
    end
    let(:editor) { class_spy(Metalware::Utils::Editor).as_stubbed_const }

    AlcesUtils.mock(self, :each) do
      FileSystem.root_setup { |fs| fs.with_asset_types }
      allow(Metalware::SystemCommand).to receive(:no_capture)
      allow(HighLine).to receive(:new).and_return(mocked_highline)
      create_layout(layout_name, layout_content)
    end

    def run_sub_asseting_command
      Metalware::Utils.run_command(described_class,
                                   layout_name,
                                   parent_asset_name)
    end

    shared_examples 'creates the sub asset' do |editor_count|
      it "only opens the editor #{editor_count} times" do
        editor # Activates the spy
        run_sub_asseting_command
        expect(editor).to have_received(:open_copy).exactly(editor_count)
      end

      it 'creates the sub asset' do
        run_sub_asseting_command
        expect(alces.assets.find_by_name(sub_asset_name)).not_to be_nil
      end
    end

    context 'when saving the sub asset directly' do
      let(:highline_answer) { false }

      include_examples 'creates the sub asset', 1
    end
  end
end
