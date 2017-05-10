
require 'commander'

require 'commands/hosts'
require 'templater'
require 'iterator'

def mock_iterator_run_nodeattr
  # TODO break all running of `nodeattr` in Metalware out so can cleanly mock
  # results.
  allow_any_instance_of(
    Metalware::Iterator::Nodes
  ).to receive(
    :run_nodeattr
  ).and_return(
    ['testnode01', 'testnode02']
  )
end

def mock_templater_combiner
  @combiner_double = object_double(Metalware::Templater::Combiner.new)
  allow(
    Metalware::Templater::Combiner
  ).to receive(:new).and_return(
    @combiner_double
  )
end

def expect_it_templates_for_each_node
  expect(
    Metalware::Templater::Combiner
  ).to receive(:new).with({
    nodename: 'testnode01',
    index: 0
  }).ordered
  expect(
    Metalware::Templater::Combiner
  ).to receive(:new).with({
    nodename: 'testnode02',
    index: 1
  }).ordered
end

def expect_it_templates_for_single_node
  expect(Metalware::Templater::Combiner).to receive(:new).with({
    nodename: 'testnode01'
  })
end

def run_hosts(node_identifier, **options_hash)
  options = Commander::Command::Options.new
  options_hash.map do |option, value|
    option_setter = (option.to_s + '=').to_sym
    options.__send__(option_setter, value)
  end

  Metalware::Commands::Hosts.new([node_identifier], options)
end

describe Metalware::Commands::Hosts do

  before :each do
    mock_templater_combiner
  end

  context 'when called without group argument' do
    it 'appends to hosts file by default' do
      expect_it_templates_for_single_node
      expect(@combiner_double).to receive(:append).with(
        '/var/lib/metalware/repo/hosts/default',
        '/etc/hosts'
      )

      run_hosts('testnode01')
    end

    it 'uses a different template if template option passed' do
      expect_it_templates_for_single_node
      expect(@combiner_double).to receive(:append).with(
        '/var/lib/metalware/repo/hosts/my_template',
        '/etc/hosts'
      )

      run_hosts('testnode01', template: 'my_template')
    end

    context 'when dry-run' do
      it 'outputs what would be appended' do
        expect_it_templates_for_single_node
        expect(@combiner_double).to receive(:file).with(
          '/var/lib/metalware/repo/hosts/default'
        )

        run_hosts('testnode01', dry_run: true)
      end
    end
  end

  context 'when called for group' do
    before :each do
      mock_iterator_run_nodeattr
    end

    it 'appends to hosts file by default' do
      expect_it_templates_for_each_node

      expect(@combiner_double).to receive(:append).twice.with(
        '/var/lib/metalware/repo/hosts/default',
        '/etc/hosts'
      )

      run_hosts('testnodes', group: true)
    end

    context 'when dry-run' do
      it 'outputs what would be appended' do
        expect_it_templates_for_each_node

        expect(@combiner_double).to receive(:file).twice.with(
          '/var/lib/metalware/repo/hosts/default'
        )

        run_hosts('testnodes', group: true, dry_run: true)
      end
    end
  end
end
