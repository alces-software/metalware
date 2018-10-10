
# frozen_string_literal: true

require 'shared_examples/hash_merger_namespace'

require 'namespaces/alces'
require 'constants'
require 'hash_mergers'
require 'recursive_open_struct'
require 'spec_utils'

RSpec.describe Metalware::Namespaces::Node do
  context 'with AlcesUtils' do
    include AlcesUtils

    AlcesUtils.mock self, :each do
      hexadecimal_ip(mock_node('test_node'))
      mock_group(AlcesUtils.default_group)
    end

    subject { alces.nodes.first }

    include_examples Metalware::Namespaces::HashMergerNamespace
  end

  context 'without AlcesUtils' do
    let(:alces) do
      a = Metalware::Namespaces::Alces.new
      allow(a).to receive(:groups).and_return(
        Metalware::Namespaces::MetalArray.new(
          [
            Metalware::Namespaces::Group
              .new(a, 'primary_group', index: primary_group_index),
          ]
        )
      )
      a
    end

    let(:test_value) { 'test value set in namespace/node_spec.rb' }
    let(:primary_group_index) { 'primary_group_index' }
    let(:node_name) { 'node02' }
    let(:node_array) { ['some_other_node', node_name] }

    let(:config_hash) do
      Metalware::Constants::HASH_MERGER_DATA_STRUCTURE.new(
        key: test_value,
        erb_value1: '<%= alces.node.config.key  %>'
      ) { |template_string| node.render_string(template_string) }
    end

    let(:node) { described_class.create(alces, node_name) }

    ##
    # Mocks the HashMergers
    #
    before do
      config_double = instance_double(Metalware::HashMergers::Config,
                                      merge: config_hash)
      answer_double = instance_double(Metalware::HashMergers::Answer,
                                      merge: {})
      allow(Metalware::HashMergers::Config).to receive(:new)
        .and_return(config_double)
      allow(Metalware::HashMergers::Answer).to receive(:new)
        .and_return(answer_double)

      ##
      # Spoofs the results of NodeattrInterface
      #
      allow(Metalware::NodeattrInterface).to \
        receive(:genders_for_node).and_return(['primary_group'])
      allow(Metalware::NodeattrInterface).to \
        receive(:nodes_in_gender).and_return(node_array)
      allow(Metalware::NodeattrInterface).to \
        receive(:all_nodes).and_return(node_array)

      # Spoofs the hostip
      use_mock_determine_hostip_script
    end

    it 'can access the node name' do
      expect(node.name).to eq(node_name)
    end

    it 'can retreive a simple config value for the node' do
      expect(node.config.key).to eq(test_value)
    end

    it 'config parameters can reference other config parameters' do
      expect(node.config.erb_value1).to eq(test_value)
    end

    it 'can find its group index' do
      expect(node.group.index).to eq(primary_group_index)
    end

    it 'can determine the node index' do
      expect(node.index).to eq(2)
    end

    it 'has a kickstart_url' do
      expected = "http://1.2.3.4/metalware/kickstart/#{node_name}"
      expect(node.kickstart_url).to eq(expected)
    end

    it 'has a build complete url' do
      exp = "http://1.2.3.4/metalware/exec/kscomplete.php?name=#{node_name}"
      expect(node.build_complete_url).to eq(exp)
    end

    describe '#==' do
      let(:foonode) { described_class.create(alces, 'foonode') }
      let(:barnode) { described_class.create(alces, 'barnode') }

      it 'returns false if other object is not a Node' do
        other_object = Struct.new(:name).new('foonode')
        expect(foonode).not_to eq(other_object)
      end

      it 'defines nodes with the same name as equal' do
        expect(foonode).to eq(foonode)
      end

      it 'defines nodes with different names as not equal' do
        expect(foonode).not_to eq(barnode)
      end
    end

    describe '#local?' do
      context 'with a regular node' do
        subject { described_class.create(alces, 'node01') }

        it { is_expected.not_to be_local }
      end

      context "with the 'local' node" do
        subject { described_class.create(alces, 'local') }

        it { is_expected.to be_local }
      end
    end

    describe '#asset' do
      let(:content) do
        { node: { node_name.to_sym => 'asset_test' } }
      end
      let(:asset_name) { 'asset_test' }
      let(:cache) { Metalware::Cache::Asset.new }

      context 'with an assigned asset' do
        AlcesUtils.mock(self, :each) do
          create_asset(asset_name, content)
          cache.assign_asset_to_node(asset_name, node)
          cache.save
        end

        it 'loads the asset data' do
          expect(node.asset.to_h).to include(**content)
        end
      end

      context 'without an assigned asset' do
        it 'returns nil' do
          expect(node.asset).to eq(nil)
        end
      end
    end
  end

  # Test `#plugins` without the rampant mocking above.
  describe '#plugins' do
    let(:node) { described_class.create(alces, 'node01') }
    let(:alces) { Metalware::Namespaces::Alces.new }

    # XXX Need to handle situation of plugin being enabled for node but not
    # available globally?
    let(:enabled_plugin) { 'enabled_plugin' }
    let(:disabled_plugin) { 'disabled_plugin' }
    let(:unconfigured_plugin) { 'unconfigured_plugin' }
    let(:deactivated_plugin) { 'deactivated_plugin' }

    before do
      FileSystem.root_setup do |fs|
        fs.with_minimal_repo

        # Create all test plugins.
        [
          enabled_plugin,
          disabled_plugin,
          unconfigured_plugin,
          deactivated_plugin,
        ].each do |plugin|
          fs.mkdir_p File.join(Metalware::FilePath.plugins_dir, plugin)
        end

        fs.setup do
          # Activate these plugins.
          [
            enabled_plugin,
            disabled_plugin,
            unconfigured_plugin,
          ].each do |plugin|
            Metalware::Plugins.activate!(plugin)
          end
        end
      end

      # NOTE: Must be after fs setup otherwise the initially spoofed
      # genders file will be deleted
      AlcesUtils.spoof_nodeattr(self)

      # Enable/disable plugins for node as needed.
      enabled_identifier = \
        Metalware::Plugins.enabled_question_identifier(enabled_plugin)
      disabled_identitifer = \
        Metalware::Plugins.enabled_question_identifier(disabled_plugin)
      answers = {
        enabled_identifier => true,
        disabled_identitifer => false,
      }.to_json
      Metalware::Utils.run_command(
        Metalware::Commands::Configure::Node, node.name, answers: answers
      )
    end

    it 'only includes plugins enabled for node' do
      node_plugin_names = []
      node.plugins.each do |plugin|
        node_plugin_names << plugin.name
      end

      expect(node_plugin_names).to eq [enabled_plugin]
    end

    it 'uses plugin namespace for each enabled plugin' do
      first_plugin = node.plugins.first

      expect(first_plugin).to be_a(Metalware::Namespaces::Plugin)
    end

    it 'provides access to plugin namespaces by plugin name' do
      plugin = node.plugins.enabled_plugin

      expect(plugin.name).to eq enabled_plugin
    end
  end
end
