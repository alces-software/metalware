
# frozen_string_literal: true

require 'alces_utils'

RSpec.describe AlcesUtils do
  include AlcesUtils

  let :file_path { Metalware::FilePath }
  let :group_cache { Metalware::GroupCache.new }

  describe '#new' do
    it 'returns the mocked alces' do
      new_alces = Metalware::Namespaces::Alces.new
      expect(alces.equal?(new_alces)).to eq(true)
    end
  end

  describe '#define_method_testing' do
    it 'runs the method block' do
      AlcesUtils::Mock.new(self).define_method_testing do
        'value'
      end
      expect(alces.testing).to eq('value')
    end
  end

  context 'with the AlceUtils.mock method' do
    before :each do
      AlcesUtils::Mock.new(self)
                      .define_method_testing {} # Intentionally blank
    end

    it 'only has the local node by default' do
      expect(alces.nodes.length).to eq(1)
      expect(alces.nodes[0]).to be_a(Metalware::Namespaces::Local)
    end

    context 'with a block before each test' do
      AlcesUtils.mock self, :each do
        allow(alces).to receive(:testing).and_return(100)
      end

      it 'gets the value once' do
        expect(alces.testing).to eq(100)
      end

      it 'gets the value twice' do
        expect(alces.testing).to eq(100)
      end
    end

    context 'with the config mocked' do
      let :domain_config do
        { key: 'domain' }
      end

      AlcesUtils.mock self, :each do
        config(alces.domain, domain_config)
      end

      it 'mocks the config' do
        expect(alces.domain.config.key).to eq('domain')
      end
    end

    context 'with a mocked config' do
      AlcesUtils.mock self, :each do
        validation_off
      end

      it 'turns the validation off' do
        expect(Metalware::Constants::SKIP_VALIDATION).to be true
      end
    end

    context 'with blank config' do
      AlcesUtils.mock self, :each do
        with_blank_config_and_answer(alces.domain)
      end

      it 'has a blank config' do
        expect(alces.domain.config.to_h).to be_empty
      end

      it 'has a blank answer' do
        expect(alces.domain.answer.to_h).to be_empty
      end

      it 'can still overide the config' do
        AlcesUtils.mock self do
          config(alces.domain, key: 'domain')
        end

        expect(alces.domain.config.key).to eq('domain')
      end
    end

    describe '#mock_group' do
      let :group { 'some random group' }
      let :group2 { 'some other group' }

      AlcesUtils.mock self, :each do
        expect(File.exist?(file_path.group_cache)).to eq(false)
        mock_group(group)
      end

      it 'creates the group cache' do
        expect(File.exist?(file_path.group_cache)).to eq(true)
      end

      it 'creates the group' do
        expect(alces.groups.send(group).name).to eq(group)
      end

      it 'can add another group' do
        alces.groups # Initializes the old groups first
        AlcesUtils.mock(self) { mock_group(group2) }
        expect(alces.groups.send(group2).name).to eq(group2)
      end

      # The mocking would otherwise alter the actual file
      it 'errors if FakeFS is off' do
        FakeFS.deactivate!
        expect do
          AlcesUtils.mock(self) { mock_group(group2) }
        end.to raise_error(RuntimeError)
      end

      it 'returns the new mocked group' do
        name = 'my-super-new-group'
        AlcesUtils.mock self do
          expect(mock_group(name).name).to eq(name)
        end
      end
    end

    describe '#mock_node' do
      let :name { 'some_random_test_node3456734' }

      AlcesUtils.mock self, :each do
        allow(alces).to receive(:node).and_return(mock_node(name))
      end

      it 'creates the mock node' do
        expect(alces.node.name).to eq(name)
      end

      it 'appears in the nodes list' do
        expect(alces.nodes.length).to eq(2)
        expect(alces.nodes.find_by_name(name).name).to eq(name)
      end

      it 'adds the node to default test group' do
        expect(alces.node.genders).to eq([AlcesUtils.default_group])
      end

      it 'errors if the node already exists' do
        expect do
          AlcesUtils.mock(self) { mock_node(name) }
        end.to raise_error(Metalware::InternalError)
      end

      context 'with a new node' do
        let :new_node { 'some_random_new_node4362346' }
        let :genders { ['_some_group_1', '_some_group_2'] }

        AlcesUtils.mock(self, :each) { mock_node(new_node, *genders) }

        it 'uses the genders input' do
          node = alces.nodes.find_by_name(new_node)
          expect(node.genders).to eq(genders)
        end
      end
    end

    describe '#create_asset' do
      let :asset_name { 'my-new-asset' }
      let :asset_data { { key: "#{asset_name}-data" } }

      AlcesUtils.mock(self, :each) do
        create_asset(asset_name, asset_data)
      end

      it 'creates an new asset' do
        asset = alces.assets.find_by_name(asset_name)
        expect(asset).not_to eq(nil)
        expect(asset.to_h).to include(:metadata, **asset_data)
      end

      it 'can add new assets after the asset array is loaded' do
        new_name = 'new-asset-name'
        new_data = { key: "#{new_name}-data" }
        alces.assets

        AlcesUtils.mock(self) do
          create_asset(new_name, new_data)
        end
        new_asset = alces.assets.find_by_name(new_name)

        expect(new_asset).not_to eq(nil)
        expect(new_asset.to_h).to include(:metadata, **new_data)
      end
    end

    describe '#reset_alces' do
      before :each do
        @old_alces = alces
        AlcesUtils.mock(self) do
          config(alces.domain, key: 'I should be deleted in the reset')
        end
        reset_alces
      end

      it 'resets alces to a new instance' do
        expect(alces).not_to eq(@old_alces)
      end

      it 'removes the old config mocking' do
        expect(alces.domain.config.keys).to be_nil
      end

      it 'sets the Alces.new method to return the new alces object' do
        new_alces = Metalware::Namespaces::Alces.new
        expect(new_alces).to eq(alces)
      end

      it 'returns the new version of alces' do
        return_from_reset_alces = reset_alces
        expect(return_from_reset_alces).to eq(alces)
      end
    end
  end

  describe '#redirect_std' do
    let :test_str { 'Testing' }

    it 'can redirect stdout' do
      io = AlcesUtils.redirect_std(:stdout) do
        $stdout.puts test_str
      end
      expect(io[:stdout].read.chomp).to eq(test_str)
    end

    it 'can redirect stderr' do
      io = AlcesUtils.redirect_std(:stderr) do
        warn test_str
      end
      expect(io[:stderr].read.chomp).to eq(test_str)
    end

    it 'resets stdout' do
      test_stdout = StringIO.new
      old_stdout = $stdout
      begin
        $stdout = test_stdout
        AlcesUtils.redirect_std(:stdout) do
          puts 'I should be captured'
        end
        puts test_str
      ensure
        $stdout = old_stdout
      end
      test_stdout.rewind
      expect(test_stdout.read.chomp).to eq(test_str)
    end
  end
end
