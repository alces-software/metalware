
require 'timeout'
require 'fakefs/safe'

require 'commands/build'
require 'node'
require 'spec_utils'


RSpec.describe Metalware::Commands::Build do
  def run_build(node_identifier, **options_hash)
    # Run command in timeout as `build` will wait indefinitely, but want to
    # abort tests if it looks like this is happening.
    Timeout::timeout 0.5 do
      SpecUtils.run_command(
        Metalware::Commands::Build, node_identifier, **options_hash
      )
    end
  end

  # Makes `Node.new` return real `Node`s, but with certain methods stubbed to
  # not depend on environment.
  def use_mock_nodes(not_built_nodes: [])
    allow(
      Metalware::Node
    ).to receive(:new).and_wrap_original do |original_new, config, name|
      original_new.call(config, name).tap do |node|
        # Stub this as depends on `gethostip` and `/etc/hosts`
        allow(node).to receive(:hexadecimal_ip).and_return(node.name + '_HEX_IP')

        # Stub this to return that node is built, unless explicitly pass in
        # node as not built.
        node_built = !not_built_nodes.include?(node.name)
        allow(node).to receive(:built?).and_return(node_built)
      end
    end
  end

  def expect_runs_longer_than(seconds, &block)
    expect do
      Timeout::timeout(seconds, &block)
    end.to raise_error TimeoutError
  end

  before :each do
    allow(Metalware::Templater).to receive(:render_to_file)
    use_mock_nodes
    SpecUtils.use_mock_genders(self)
    SpecUtils.use_unit_test_config(self)
    SpecUtils.fake_download_error(self)
    SpecUtils.mock_repo_exists(self)
  end

  context 'when called without group argument' do
    def expected_template_parameters
      {
        nodename: 'testnode01',
        index: 0,
        firstboot: true,
        files: SpecUtils.create_mock_build_files_hash(self, 'testnode01'),
      }
    end

    it 'renders default standard templates for given node' do
      expect(Metalware::Templater).to receive(:render_to_file).with(
        instance_of(Metalware::Config),
        '/var/lib/metalware/repo/kickstart/default',
        '/var/lib/metalware/rendered/kickstart/testnode01',
        expected_template_parameters,
      )
      expect(Metalware::Templater).to receive(:render_to_file).with(
        instance_of(Metalware::Config),
        '/var/lib/metalware/repo/pxelinux/default',
        '/var/lib/tftpboot/pxelinux.cfg/testnode01_HEX_IP',
        expected_template_parameters,
      ).at_least(:once)

      run_build('testnode01')
    end

    it 'uses different standard templates if template options passed' do
      expect(Metalware::Templater).to receive(:render_to_file).with(
        instance_of(Metalware::Config),
        '/var/lib/metalware/repo/kickstart/my_kickstart',
        '/var/lib/metalware/rendered/kickstart/testnode01',
        expected_template_parameters,
      )
      expect(Metalware::Templater).to receive(:render_to_file).with(
        instance_of(Metalware::Config),
        '/var/lib/metalware/repo/pxelinux/my_pxelinux',
        '/var/lib/tftpboot/pxelinux.cfg/testnode01_HEX_IP',
        expected_template_parameters,
      ).at_least(:once)

      run_build(
        'testnode01',
        kickstart: 'my_kickstart',
        pxelinux: 'my_pxelinux'
      )
    end

    it 'renders pxelinux once with firstboot true if node does not build' do
      time_to_wait = 0.2
      use_mock_nodes(not_built_nodes: 'testnode01')

      expect(Metalware::Templater).to receive(:render_to_file).with(
        instance_of(Metalware::Config),
        '/var/lib/metalware/repo/pxelinux/default',
        '/var/lib/tftpboot/pxelinux.cfg/testnode01_HEX_IP',
        expected_template_parameters,
      ).once

      expect_runs_longer_than(time_to_wait) { run_build('testnode01') }
    end

    it 'renders pxelinux twice with firstboot switched if node builds' do
      expect(Metalware::Templater).to receive(:render_to_file).with(
        instance_of(Metalware::Config),
        '/var/lib/metalware/repo/pxelinux/default',
        '/var/lib/tftpboot/pxelinux.cfg/testnode01_HEX_IP',
        expected_template_parameters,
      ).once.ordered
      expect(Metalware::Templater).to receive(:render_to_file).with(
        instance_of(Metalware::Config),
        '/var/lib/metalware/repo/pxelinux/default',
        '/var/lib/tftpboot/pxelinux.cfg/testnode01_HEX_IP',
        expected_template_parameters.merge(firstboot: false),
      ).once.ordered

       run_build('testnode01')
    end

    describe 'files rendering' do
      it 'renders only files which could be retrieved' do
        # XXX This test is an experiment with using `FakeFS` and explicitly
        # declaring the files it depends on, rather than relying on the
        # combination of fudging config values, file paths and stubbing methods
        # we do elsewhere. This may be a more robust and less brittle approach.
        FakeFS do
          # Clone in test Metalware configs at expected path, so can find
          # `unit-test.yaml`.
          # XXX Rather than stubbing `Constants::DEFAULT_CONFIG_PATH` and then
          # cloning the test config there, could just clone this where it is
          # normally expected.
          FakeFS::FileSystem.clone('spec/fixtures/configs/')

          # Clone in needed repo files to expected locations.
          # XXX Once removed `repo_configs_path` from config can simplify this
          # to use normal repo location for configs.
          FakeFS::FileSystem.clone('spec/fixtures/repo/config', '/spec/fixtures/repo/config')
          FileUtils.mkdir_p('/var/lib/metalware/repo/files/testnodes')
          FileUtils.touch('/var/lib/metalware/repo/files/testnodes/some_file_in_repo')

          expect(Metalware::Templater).to receive(:render_to_file).with(
            instance_of(Metalware::Config),
            '/var/lib/metalware/repo/files/testnodes/some_file_in_repo',
            '/var/lib/metalware/rendered/testnode01/namespace01/some_file_in_repo',
            expected_template_parameters
          )

          # Should not try to render any other build files for this node.
          node_rendered_path = '/var/lib/metalware/rendered/testnode01'
          expect(Metalware::Templater).not_to receive(:render_to_file).with(
            anything, /^#{node_rendered_path}/, anything
          )

          run_build('testnode01')
        end
      end
    end
  end

  context 'when called for group' do
    it 'renders standard templates for each node' do
      expect(Metalware::Templater).to receive(:render_to_file).with(
        instance_of(Metalware::Config),
        '/var/lib/metalware/repo/kickstart/my_kickstart',
        '/var/lib/metalware/rendered/kickstart/testnode01',
        hash_including(nodename: 'testnode01', index: 0)
      )
      expect(Metalware::Templater).to receive(:render_to_file).with(
        instance_of(Metalware::Config),
        '/var/lib/metalware/repo/pxelinux/my_pxelinux',
        '/var/lib/tftpboot/pxelinux.cfg/testnode01_HEX_IP',
        hash_including(nodename: 'testnode01', index: 0)
      )
      expect(Metalware::Templater).to receive(:render_to_file).with(
        instance_of(Metalware::Config),
        '/var/lib/metalware/repo/kickstart/my_kickstart',
        '/var/lib/metalware/rendered/kickstart/testnode02',
        hash_including(nodename: 'testnode02', index: 1)
      )
      expect(Metalware::Templater).to receive(:render_to_file).with(
        instance_of(Metalware::Config),
        '/var/lib/metalware/repo/pxelinux/my_pxelinux',
        '/var/lib/tftpboot/pxelinux.cfg/testnode02_HEX_IP',
        hash_including(nodename: 'testnode02', index: 1)
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
