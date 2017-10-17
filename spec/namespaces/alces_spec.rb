
# frozen_string_literal: true

require 'namespaces/alces'
require 'hash_mergers'
require 'config'
require 'alces_utils'

RSpec.describe Metalware::Namespaces::Alces do
  include AlcesUtils

  AlcesUtils.mock self, :each do
    validation_off
    with_blank_config_and_answer(alces.domain)
  end

  describe '#template' do
    before :each do
      alces_mock = AlcesUtils::Mock.new(self)

      # Creates a testing on alces that returns the MetalROS
      alces_mock.define_method_testing do
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
end
