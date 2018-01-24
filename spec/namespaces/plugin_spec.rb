
# frozen_string_literal: true

require 'spec_utils'

RSpec.describe Metalware::Namespaces::Plugin do
  include AlcesUtils

  let :config { Metalware::Config.new }

  let :node do
    Metalware::Namespaces::Node.create(alces, node_name)
  end
  let :node_name { 'some_node' }
  let :node_group_name { 'some_group' }

  let :plugin_name { 'my_plugin' }
  let :plugin do
    Metalware::Plugins.all.find { |plugin| plugin.name == plugin_name }
  end

  subject { described_class.new(node, plugin) }

  before :each do
    Metalware::Config.cache = config

    FileSystem.root_setup do |fs|
      fs.setup do
        plugin_config_dir = File.join(file_path.plugins_dir, plugin_name, 'config')
        FileUtils.mkdir_p plugin_config_dir

        File.write(file_path.genders, "#{node_name} #{node_group_name}\n")
      end
    end
  end

  after :each do
    Metalware::Config.clear_cache
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
        }
      }.each do |plugin_config, config_data|
        Metalware::Data.dump(plugin_config, config_data)
      end

      expect(subject.config.domain_parameter).to eq('domain_value')
      expect(subject.config.group_parameter).to eq('group_value')
      expect(subject.config.node_parameter).to eq('node_value')
    end
  end
end
