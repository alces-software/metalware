
require 'timeout'

require 'commands/build'
require 'node'
require 'spec_utils'

# XXX Need to mock nodeattr in this and `hosts` tests? Could just use `genders`
# from fixtures?
# TODO Make tests for build timing actually depend on files appearing as
# command is running? Currently just run command multiple times. Best way to do
# this I think would be to have integration tests which run the `metal build`
# and wait for things to happen + create the build files. To have this work
# when running locally need to have config file where location to store marker
# files, time to sleep when polling etc come from.

describe Metalware::Commands::Build do
  TEST_BUILD_POLL_SLEEP = 0.1

  def run_build(node_identifier, **options_hash)
    SpecUtils.run_command(
      Metalware::Commands::Build, node_identifier, **options_hash
    )
  end

  # Makes `Node.new` return real `Node`s, but with certain methods stubbed to
  # not depend on environment.
  def use_mock_nodes(not_built_nodes: [])
    allow(
      Metalware::Node
    ).to receive(:new).and_wrap_original do |original_new, name|
      original_new.call(name).tap do |node|
        # Stub this as depends on `gethostip` and `/etc/hosts`
        allow(node).to receive(:hexadecimal_ip).and_return(node.name + '_HEX_IP')

        # Stub this to return that node is built, unless explicitly pass in
        # node as not built.
        node_built = !not_built_nodes.include?(node.name)
        allow(node).to receive(:built?).and_return(node_built)
      end
    end
  end

  def use_short_build_poll_time
    stub_const('Metalware::Constants::BUILD_POLL_SLEEP', TEST_BUILD_POLL_SLEEP)
  end

  def expect_runs_longer_than(seconds, &block)
    expect do
      Timeout::timeout(seconds, &block)
    end.to raise_error TimeoutError
  end

  def expect_runs_within(seconds, &block)
    expect do
      Timeout::timeout(seconds, &block)
    end.not_to raise_error TimeoutError
  end

  before :each do
    SpecUtils.use_mock_templater(self)
    use_mock_nodes
    stub_const('Metalware::Constants::BUILD_POLL_SLEEP', 0)
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

    it 'waits for the node to report as built before exiting' do
      allow(@templater).to receive(:save)
      use_short_build_poll_time
      time_to_wait = TEST_BUILD_POLL_SLEEP * 2

      use_mock_nodes(not_built_nodes: 'testnode01')
      expect_runs_longer_than(time_to_wait) { run_build('testnode01') }

      use_mock_nodes
      expect_runs_within(time_to_wait) { run_build('testnode01') }
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

    it 'waits for all nodes to report as built before exiting' do
      allow(@templater).to receive(:save)
      use_short_build_poll_time
      time_to_wait = TEST_BUILD_POLL_SLEEP * 2

      use_mock_nodes(not_built_nodes: ['testnode01', 'testnode02'])
      expect_runs_longer_than(time_to_wait) {
        run_build('testnodes', group: true)
      }

      use_mock_nodes(not_built_nodes: ['testnode02'])
      expect_runs_longer_than(time_to_wait) {
        run_build('testnodes', group: true)
      }

      use_mock_nodes
      expect_runs_within(time_to_wait) {
        run_build('testnodes', group: true)
      }
    end
  end

end
