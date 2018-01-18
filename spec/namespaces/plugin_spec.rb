
# frozen_string_literal: true

RSpec.describe Metalware::Namespaces::Plugin do
  let :plugin_dir_path { File.join(Metalware::FilePath.plugins_dir, 'my_plugin') }
  let :config { Metalware::Config.new }

  before :each do
    Metalware::Config.cache = config

    FileSystem.root_setup do |fs|
      fs.setup do
        FileUtils.mkdir_p plugin_dir_path
      end
    end
  end

  after :each do
    Metalware::Config.clear_cache
  end

  subject do
    described_class.new(Metalware::Plugins.all.first)
  end

  describe '#name' do
    it 'returns plugin name' do
      expect(subject.name).to eq 'my_plugin'
    end
  end
end
