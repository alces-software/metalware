
# frozen_string_literal: true

require 'spec_utils'

RSpec.describe Metalware::Namespaces::Plugin do
  include AlcesUtils

  subject { described_class.new(plugin, node: node) }

  let(:node) do
    Metalware::Namespaces::Node.create(alces, node_name)
  end
  let(:node_name) { 'some_node' }
  let(:node_group_name) { 'some_group' }

  let(:plugin_name) { 'my_plugin' }
  let(:plugin) do
    Metalware::Plugins.all.find { |plugin| plugin.name == plugin_name }
  end

  before do
    FileSystem.root_setup do |fs|
      fs.setup do
        plugins_path = Metalware::FilePath.plugins_dir
        plugin_config_dir = File.join(plugins_path, plugin_name, 'config')
        FileUtils.mkdir_p plugin_config_dir

        File.write(
          Metalware::FilePath.genders, "#{node_name} #{node_group_name}\n"
        )
      end
    end
  end

  describe '#name' do
    it 'returns plugin name' do
      expect(subject.name).to eq 'my_plugin'
    end
  end

  describe '#config' do
    it 'provides access to merged plugin config for node' do
      {
        plugin.domain_config => {
          domain_parameter: 'domain_value',
          group_parameter: 'domain_value',
          node_parameter: 'domain_value',
        },
        plugin.group_config(node_group_name) => {
          group_parameter: 'group_value',
          node_parameter: 'group_value',
        },
        plugin.node_config(node_name) => {
          node_parameter: 'node_value',
        },
      }.each do |plugin_config, config_data|
        Metalware::Data.dump(plugin_config, config_data)
      end

      expect(subject.config.domain_parameter).to eq('domain_value')
      expect(subject.config.group_parameter).to eq('group_value')
      expect(subject.config.node_parameter).to eq('node_value')
    end

    it 'supports templating, with access to node namespace values' do
      Metalware::Data.dump(plugin.domain_config,
                           node_name: '<%= node.name %>')

      expect(subject.config.node_name).to eq(node.name)
    end
  end

  describe '#files' do
    it 'provides access to build file hashes for plugin' do
      Metalware::Data.dump(plugin.domain_config,
                           files: {
                             some_files_section: [
                               '/path/to/some/file',
                             ],
                           })

      expect(subject.files)
        .to be_a(Metalware::HashMergers::MetalRecursiveOpenStruct)
      expected_files_hash = subject.files.some_files_section.first
      expect(expected_files_hash.raw).to eq('/path/to/some/file')
    end
  end
end
