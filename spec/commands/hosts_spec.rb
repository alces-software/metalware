
require 'commands/hosts'
require 'templater'
require 'spec_utils'


RSpec.describe Metalware::Commands::Hosts do

  def run_hosts(node_identifier, **options_hash)
    SpecUtils.run_command(
      Metalware::Commands::Hosts, node_identifier, **options_hash
    )
  end

  before :each do
    SpecUtils.use_mock_genders(self)
    SpecUtils.use_unit_test_config(self)
    SpecUtils.mock_repo_exists(self)
  end

  context 'when called without group argument' do
    it 'appends to hosts file by default' do
      expect(Metalware::Templater).to receive(:render_and_append_to_file).with(
        instance_of(Metalware::Config),
        '/var/lib/metalware/repo/hosts/default',
        '/etc/hosts',
        hash_including(nodename: 'testnode01', index: 0)
      )

      run_hosts('testnode01')
    end

    it 'uses a different template if template option passed' do
      expect(Metalware::Templater).to receive(:render_and_append_to_file).with(
        instance_of(Metalware::Config),
        '/var/lib/metalware/repo/hosts/my_template',
        '/etc/hosts',
        hash_including(nodename: 'testnode01', index: 0)
      )

      run_hosts('testnode01', template: 'my_template')
    end

    context 'when dry-run' do
      it 'outputs what would be appended' do
        expect(Metalware::Templater).to receive(:render_to_stdout).with(
          instance_of(Metalware::Config),
          '/var/lib/metalware/repo/hosts/default',
          hash_including(nodename: 'testnode01')
        )

        run_hosts('testnode01', dry_run: true)
      end
    end
  end

  context 'when called for group' do
    it 'appends to hosts file by default' do
      # XXX Dedupe these very similar assertions
      expect(Metalware::Templater).to receive(:render_and_append_to_file).with(
        instance_of(Metalware::Config),
        '/var/lib/metalware/repo/hosts/default',
        '/etc/hosts',
        hash_including(nodename: 'testnode01', index: 0)
      )
      expect(Metalware::Templater).to receive(:render_and_append_to_file).with(
        instance_of(Metalware::Config),
        '/var/lib/metalware/repo/hosts/default',
        '/etc/hosts',
        hash_including(nodename: 'testnode02', index: 1)
      )
      expect(Metalware::Templater).to receive(:render_and_append_to_file).with(
        instance_of(Metalware::Config),
        '/var/lib/metalware/repo/hosts/default',
        '/etc/hosts',
        hash_including(nodename: 'testnode03', index: 2)
      )

      run_hosts('testnodes', group: true)
    end

    context 'when dry-run' do
      it 'outputs what would be appended' do
        # XXX Dedupe these too
        expect(Metalware::Templater).to receive(:render_to_stdout).with(
          instance_of(Metalware::Config),
          '/var/lib/metalware/repo/hosts/default',
          hash_including(nodename: 'testnode01', index: 0)
        )
        expect(Metalware::Templater).to receive(:render_to_stdout).with(
          instance_of(Metalware::Config),
          '/var/lib/metalware/repo/hosts/default',
          hash_including(nodename: 'testnode02', index: 1)
        )
        expect(Metalware::Templater).to receive(:render_to_stdout).with(
          instance_of(Metalware::Config),
          '/var/lib/metalware/repo/hosts/default',
          hash_including(nodename: 'testnode03', index: 2)
        )

        run_hosts('testnodes', group: true, dry_run: true)
      end
    end
  end
end
