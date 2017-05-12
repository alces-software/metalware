
require 'commands/build'
require 'node'
require 'spec_utils'


describe Metalware::Commands::Build do
  def run_build(node_identifier, **options_hash)
    SpecUtils.run_command(
      Metalware::Commands::Build, node_identifier, **options_hash
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

  before :each do
    SpecUtils.use_mock_templater(self)
    use_mock_nodes
  end

  context 'when called without group argument' do
    it 'renders default templates for given node' do
      SpecUtils.expect_it_templates_for_single_node(self)
      expect(@templater).to receive(:save).with(
        '/var/lib/metalware/repo/kickstart/default',
        '/var/lib/metalware/rendered/kickstart/testnode01'
      )
      expect(@templater).to receive(:save).with(
        '/var/lib/metalware/repo/pxelinux/default',
        '/var/lib/tftpboot/pxelinux.cfg/testnode01_HEX_IP'
      )

      run_build('testnode01')
    end

    it 'uses different templates if template options passed' do
      SpecUtils.expect_it_templates_for_single_node(self)
      expect(@templater).to receive(:save).with(
        '/var/lib/metalware/repo/kickstart/my_kickstart',
        '/var/lib/metalware/rendered/kickstart/testnode01'
      )
      expect(@templater).to receive(:save).with(
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
      SpecUtils.mock_iterator_run_nodeattr(self)
    end

    it 'renders templates for each node' do
      SpecUtils.expect_it_templates_for_each_node(self)
      expect(@templater).to receive(:save).with(
        '/var/lib/metalware/repo/kickstart/my_kickstart',
        '/var/lib/metalware/rendered/kickstart/testnode01'
      )
      expect(@templater).to receive(:save).with(
        '/var/lib/metalware/repo/pxelinux/my_pxelinux',
        '/var/lib/tftpboot/pxelinux.cfg/testnode01_HEX_IP'
      )
      expect(@templater).to receive(:save).with(
        '/var/lib/metalware/repo/kickstart/my_kickstart',
        '/var/lib/metalware/rendered/kickstart/testnode02'
      )
      expect(@templater).to receive(:save).with(
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
