
# frozen_string_literal: true

require 'namespaces/alces'
require 'hash_mergers'
require 'config'
require 'alces_utils'

RSpec.describe Metalware::Namespaces::Alces do
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
          infinite_value2: '<%= alces.testing.infinite_value1 %>'
        ) do |template_string|
          alces.render_erb_template(template_string)
        end
      end
    end

    it 'it can template a simple value' do
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
  end

  describe '#local' do
    it 'errors if not initialized' do
      allow(alces).to receive(:nodes)
        .and_return(Metalware::Namespaces::MetalArray.new([]))

      expect do
        alces.local
      end.to raise_error(Metalware::UninitializedLocalNode)
    end

    it 'returns the local node' do
      local = Metalware::Namespaces::Node.create(alces, 'local')
      nodes = double('nodes', local: local)
      allow(alces).to receive(:nodes).and_return(nodes)

      expect(alces.local).to be_a(Metalware::Namespaces::Local)
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
    let :domain_config { { key: 'domain' } }

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

  it 'templates have nil detection' do
    AlcesUtils.mock self do
      config(alces.domain, nil: nil)
    end
    expect(Metalware::MetalLog.metal_log).to \
      receive(:warn).once.with(/.*domain.config.nil\Z/)
    render_template('<%= domain.config.nil %>')
  end

  describe '#scope' do
    let :scope_template { '<%= alces.scope.class %>' }
    let :node_class { Metalware::Namespaces::Node }
    let :group_class { Metalware::Namespaces::Group }
    let :node_double { double(node_class, class: node_class) }
    let :group_double { double(group_class, class: group_class) }

    def render_scope_template(**dynamic)
      alces.render_erb_template(scope_template, **dynamic).constantize
    end

    # TODO: Remove this redirect, it will be replaced by the scope eventually
    before :each do
      allow(Metalware::Config.cache).to \
        receive(:alces_default_to_domain_scope).and_return(false)
    end

    it 'defaults to the Domain namespace' do
      expect(render_scope_template).to eq(alces.domain.class)
    end

    it 'errors if a group and node are both in scope' do
      expect {
        render_scope_template(node: node_double, group: group_double)
      }.to raise_error(Metalware::InternalError)
    end

    it 'can set a node as the scope' do
      expect(render_scope_template(node: node_double)).to eq(node_class)
    end

    it 'can set a group as the scope' do
      expect(render_scope_template(group: group_double)).to eq(group_class)
    end
  end
end
