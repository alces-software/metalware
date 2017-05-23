
require 'yaml'

require 'config'
require 'exceptions'
require 'constants'
require 'spec_utils'


describe Metalware::Config do
  it 'can have default values retrieved' do
    config_file = SpecUtils.fixtures_config('empty.yaml')
    config = Metalware::Config.new(config_file)
    expect(config.built_nodes_storage_path).to eq('/var/lib/metalware/cache/built-nodes')
    expect(config.rendered_files_path).to eq('/var/lib/metalware/rendered')
    expect(config.build_poll_sleep).to eq(10)
  end

  it 'can have set values retrieved over defaults' do
    config_file = SpecUtils.fixtures_config('non-empty.yaml')
    config = Metalware::Config.new(config_file)
    expect(config.built_nodes_storage_path).to eq('/built/nodes')
    expect(config.rendered_files_path).to eq('/rendered/files')
    expect(config.build_poll_sleep).to eq(5)
  end

  it 'raises if config file does not exist' do
    config_file = File.join(FIXTURES_PATH, 'configs/non-existent.yaml')
    expect {
      Metalware::Config.new(config_file)
    }.to raise_error(Metalware::MetalwareError)
  end

  it 'uses default config file if none given' do
    expect(YAML).to receive(:load_file).with(
      Metalware::Constants::DEFAULT_CONFIG_PATH
    )

    Metalware::Config.new(nil)
  end
end
