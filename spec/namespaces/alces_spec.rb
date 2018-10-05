
# frozen_string_literal: true

require 'namespaces/alces'
require 'hash_mergers'
require 'alces_utils'

RSpec.describe Metalware::Namespaces::Alces do
  # TODO: The Alces class should not be tested with AlcesUtils
  # Remove AlcesUtils and mock the configs blank manually
  include AlcesUtils

  AlcesUtils.mock self, :each do
    with_blank_config_and_answer(alces.domain)
  end

  describe '#render_erb_template' do
    AlcesUtils.mock self, :each do
      define_method_testing do
        Metalware::HashMergers::MetalRecursiveOpenStruct.new(
          key: 'value',
          embedded_key: '<%= alces.testing.key %>',
          infinite_value1: '<%= alces.testing.infinite_value2 %>',
          infinite_value2: '<%= alces.testing.infinite_value1 %>',
          false_key: false
        ) do |template_string|
          alces.render_erb_template(template_string)
        end
      end
    end

    it 'can template a simple value' do
      expect(render_template('<%= alces.testing.key %>')).to eq('value')
    end

    it 'can do a single erb replacement' do
      rendered = render_template('<%= alces.testing.embedded_key %>')
      expect(rendered).to eq('value')
    end

    it 'errors if recursion depth is exceeded' do
      expect do
        output = render_template('<%= alces.testing.infinite_value1 %>')
        STDERR.puts "Template output: #{output}"
      end.to raise_error(Metalware::RecursiveConfigDepthExceededError)
    end

    it 'evalutes the false string as Falsey' do
      template = '<%= alces.testing.false_key ? "true" : "false" %>'
      expect(render_template(template)).to eq(false)
    end

    context 'with a delay whilst rendering templates' do
      let(:template) { '<% sleep 0.2 %><%= key %>' }
      let(:long_sleep) { '<% sleep 0.3 %>' }

      def render_delay_template_in_thread
        Thread.new do
          rendered = alces.render_erb_template(template, key: 'correct')
          expect(rendered).to eq('correct')
        end
      end

      it 'preserve the scope when threaded' do
        t = render_delay_template_in_thread
        sleep 0.1
        alces.render_erb_template(long_sleep, key: 'incorrect scope')
        t.join
      end
    end
  end

  describe '#local' do
    it 'errors if not initialized' do
      allow(alces).to receive(:nodes)
        .and_return(Metalware::Namespaces::MetalArray.new([]))

      expect do
        alces.local
      end.to raise_error(Metalware::UninitializedLocalNode)
    end
  end

  # NOTE: Trailing/ (leading) white space should be ignored for the
  # conversion. Hence why some of the strings have spaces
  describe 'parses the rendered results' do
    it 'converts the true string' do
      expect(alces.render_erb_template(' true')).to be_a(TrueClass)
    end

    it 'converts the false string' do
      expect(alces.render_erb_template('false ')).to be_a(FalseClass)
    end

    it 'converts the nil string' do
      expect(alces.render_erb_template('nil')).to be_a(NilClass)
    end

    it 'converts integers' do
      expect(alces.render_erb_template(' 1234 ')).to eq(1234)
    end
  end

  describe 'default template namespace' do
    let(:domain_config) { { key: 'domain' } }

    AlcesUtils.mock self, :each do
      config(alces.domain, domain_config)
    end

    it 'templates against domain if no config is specified' do
      expect(render_template('<%= config.key %>')).to eq('domain')
    end
  end

  describe '#hunter' do
    context 'when no hunter cache file present' do
      it 'loads a empty Hashie' do
        expect(alces.hunter.to_h).to eq(Hashie::Mash.new)
      end
    end
  end

  context 'when a template returns nil' do
    let(:metal_log) { instance_spy(Metalware::MetalLog) }

    AlcesUtils.mock(self, :each) do
      allow(Metalware::MetalLog).to \
        receive(:metal_log).and_return(metal_log)
      config(alces.domain, nil: nil)
    end

    it 'templates have nil detection' do
      render_template('<%= domain.config.nil %>')
      expect(metal_log).to \
        have_received(:warn).once.with(/.*domain.config.nil\Z/)
    end
  end

  # Note scope is tested by rendering a template containing alces.scope
  # This allows the dynamic namespace to be set as if it was rendering a real
  # template
  describe '#scope' do
    let(:scope_template) { '<%= alces.scope.class %>' }
    let(:node_class) { Metalware::Namespaces::Node }
    let(:group_class) { Metalware::Namespaces::Group }
    let(:node_double) do
      instance_double(node_class, class: node_class)
    end
    let(:group_double) do
      instance_double(group_class, class: group_class)
    end

    def render_scope_template(**dynamic)
      alces.render_erb_template(scope_template, **dynamic).constantize
    end

    it 'defaults to the Domain namespace' do
      expect(render_scope_template).to eq(alces.domain.class)
    end

    it 'errors if a group and node are both in scope' do
      expect do
        render_scope_template(node: node_double, group: group_double)
      end.to raise_error(Metalware::ScopeError)
    end

    it 'can set a node as the scope' do
      expect(render_scope_template(node: node_double)).to eq(node_class)
    end

    it 'can set a group as the scope' do
      expect(render_scope_template(group: group_double)).to eq(group_class)
    end
  end

  shared_examples 'scope method tests' do |scope_class|
    let(:scope_str) { scope_class.to_s }
    let(:test_h) { instance_double(OpenStruct, test: scope_str) }

    let(:scope) do
      d = instance_double(scope_class, class: scope_str, config: test_h, answer: test_h)
      d.define_singleton_method(:is_a?) do |input|
        input == scope_class
      end
      d
    end

    before do
      allow(alces).to receive(:scope).and_return(scope)
    end

    def render_template(template)
      alces.render_erb_template(template)
    end

    describe '#domain' do
      it 'returns the domain namespace' do
        domain_class = Metalware::Namespaces::Domain.to_s
        expect(render_template('<%= alces.domain.class %>')).to eq(domain_class)
      end
    end

    describe '#local' do
      it 'returns the local node' do
        local_class = Metalware::Namespaces::Local.to_s
        expect(render_template('<%= alces.local.class %>')).to eq(local_class)
      end
    end

    describe '#config' do
      it 'uses the scope to obtain the config' do
        expect(render_template('<%= alces.config.test %>')).to eq(scope_str)
      end
    end

    describe '#answer' do
      it 'uses the scope to obtain the config' do
        expect(render_template('<%= alces.answer.test %>')).to eq(scope_str)
      end
    end
  end

  shared_examples '#node errors' do
    describe '#node' do
      it 'errors' do
        expect { alces.node }.to raise_error(Metalware::ScopeError)
      end
    end
  end

  shared_examples '#group errors' do
    describe '#group' do
      it 'errors' do
        expect { alces.group }.to raise_error(Metalware::ScopeError)
      end
    end
  end

  context 'with a Domain scope' do
    include_examples 'scope method tests', Metalware::Namespaces::Domain
    include_examples '#node errors'
    include_examples '#group errors'
  end

  context 'with a Node in scope' do
    include_examples 'scope method tests', Metalware::Namespaces::Node
    include_examples '#group errors'

    describe '#node' do
      it 'returns a Node' do
        expect(alces.node.class).to eq(Metalware::Namespaces::Node.to_s)
      end
    end
  end

  context 'with a Group in scope' do
    include_examples 'scope method tests', Metalware::Namespaces::Group
    include_examples '#node errors'

    describe '#group' do
      it 'returns a Group' do
        expect(alces.group.class).to eq(Metalware::Namespaces::Group.to_s)
      end
    end
  end
end
