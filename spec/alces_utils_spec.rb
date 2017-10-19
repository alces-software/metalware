
# frozen_string_literal: true

require 'alces_utils'

RSpec.describe AlcesUtils do
  include AlcesUtils

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

      it 'adds the node to test-group by default' do
        expect(alces.node.genders).to eq(['test-group'])
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
end
