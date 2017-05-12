
require 'commands/build'
require 'node'

# XXX refactor out shared parts betweenn this and `hosts_spec`.
def run_build(node_identifier, **options_hash)
  options = Commander::Command::Options.new
  options_hash.map do |option, value|
    option_setter = (option.to_s + '=').to_sym
    options.__send__(option_setter, value)
  end

  Metalware::Commands::Build.new([node_identifier], options)
end

# XXX duplicated from `hosts_spec`.
def mock_templater_combiner
  @combiner_double = object_double(Metalware::Templater::Combiner.new)
  allow(
    Metalware::Templater::Combiner
  ).to receive(:new).and_return(
    @combiner_double
  )
end

# XXX duplicated from `hosts_spec`.
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

def use_mock_nodes
  mock_nodes = [
    Metalware::Node.new('testnode01'),
    Metalware::Node.new('testnode02'),
  ]

  allow(
    Metalware::Node
  ).to receive(:new).and_return(
    *mock_nodes
  )

  mock_nodes.each do |node|
    allow(node).to receive(
      :hexadecimal_ip
    ).and_return(node.name + '_HEX_IP')
  end
end

# XXX duplicated from `hosts_spec`.
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

# XXX duplicated from `hosts_spec`.
def expect_it_templates_for_single_node
  expect(Metalware::Templater::Combiner).to receive(:new).with({
    nodename: 'testnode01'
  })
end

describe Metalware::Commands::Build do

  before :each do
    mock_templater_combiner
    use_mock_nodes
  end

  context 'when called without group argument' do
    it 'renders default templates for given node' do
      expect_it_templates_for_single_node
      expect(@combiner_double).to receive(:save).with(
        '/var/lib/metalware/repo/kickstart/default',
        '/var/lib/metalware/rendered/kickstart/testnode01'
      )
      expect(@combiner_double).to receive(:save).with(
        '/var/lib/metalware/repo/pxelinux/default',
        '/var/lib/tftpboot/pxelinux.cfg/testnode01_HEX_IP'
      )

      run_build('testnode01')
    end

    it 'uses different templates if template options passed' do
      expect_it_templates_for_single_node
      expect(@combiner_double).to receive(:save).with(
        '/var/lib/metalware/repo/kickstart/my_kickstart',
        '/var/lib/metalware/rendered/kickstart/testnode01'
      )
      expect(@combiner_double).to receive(:save).with(
        '/var/lib/metalware/repo/pxelinux/my_pxelinux',
        '/var/lib/tftpboot/pxelinux.cfg/testnode01_HEX_IP'
      )

      run_build(
        'testnode01',
        kickstart: 'my_kickstart',
        pxelinux: 'my_pxelinux'
      )
    end
  end

  context 'when called for group' do
    before :each do
      mock_iterator_run_nodeattr
    end

    it 'renders templates for each node' do
      expect_it_templates_for_each_node
      expect(@combiner_double).to receive(:save).with(
        '/var/lib/metalware/repo/kickstart/my_kickstart',
        '/var/lib/metalware/rendered/kickstart/testnode01'
      )
      expect(@combiner_double).to receive(:save).with(
        '/var/lib/metalware/repo/pxelinux/my_pxelinux',
        '/var/lib/tftpboot/pxelinux.cfg/testnode01_HEX_IP'
      )
      expect(@combiner_double).to receive(:save).with(
        '/var/lib/metalware/repo/kickstart/my_kickstart',
        '/var/lib/metalware/rendered/kickstart/testnode02'
      )
      expect(@combiner_double).to receive(:save).with(
        '/var/lib/metalware/repo/pxelinux/my_pxelinux',
        '/var/lib/tftpboot/pxelinux.cfg/testnode02_HEX_IP'
      )

      run_build(
        'testnodes',
        group: true,
        kickstart: 'my_kickstart',
        pxelinux: 'my_pxelinux'
      )
    end
  end

end
