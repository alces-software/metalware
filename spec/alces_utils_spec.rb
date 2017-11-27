
# frozen_string_literal: true

require 'alces_utils'

RSpec.describe AlcesUtils do
  include AlcesUtils

  let :file_path { Metalware::FilePath.new(metal_config) }
  let :group_cache { Metalware::GroupCache.new(metal_config) }

  describe '#new' do
    it 'returns the mocked config' do
      expect(metal_config.equal?(Metalware::Config.new)).to eq(true)
    end

    it 'returns the mocked alces' do
      new_alces = Metalware::Namespaces::Alces.new(metal_config)
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
        alces_default_to_domain_scope_off
        mock_strict(false)
      end

      it 'turns the validation off' do
        config = Metalware::Config.new
        expect(config.validation).to be_a(FalseClass)
      end

      it 'does not default to domain scope' do
        expect { alces.config }.to raise_error(NoMethodError)
      end

      it 'strict matches what is set' do
        expect(Metalware::Config.new(strict: true).cli.strict).to eq(false)
        expect(Metalware::Config.new(strict: false).cli.strict).to eq(false)
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

      it 'sets the config to blank' do
        expect(alces.groups.send(group).config.to_h).to be_empty
      end

      it 'sets the group as the in scope group' do
        expect(alces.group).to eq(alces.groups.send(group))
      end

      # The mocking would otherwise alter the actual file
      it 'errors if FakeFS is off' do
        FakeFS.deactivate!
        expect do
          AlcesUtils.mock(self) { mock_group(group2) }
        end.to raise_error(RuntimeError)
      end
    end

    describe '#mock_node' do
      let :name { 'some_random_test_node3456734' }

      AlcesUtils.mock self, :each do
        mock_node(name)
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

      it 'creates the node with a blank config and answer' do
        expect(alces.node.config.to_h).to be_empty
        expect(alces.node.answer.to_h).to be_empty
      end

      context 'with a new node' do
        let :new_node { 'some_random_new_node4362346' }
        let :genders { ['_some_group_1', '_some_group_2'] }

        AlcesUtils.mock(self, :each) { mock_node(new_node, *genders) }

        it 'sets the last mock node as alces.nodes' do
          expect(alces.node.name).to eq(new_node)
          expect(alces.nodes.length).to eq(3)
        end

        it 'uses the genders input' do
          expect(alces.node.genders).to eq(genders)
        end
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
        $stderr.puts test_str
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
