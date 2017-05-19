
require 'commands/hosts'
require 'templater'
require 'iterator'
require 'spec_utils'


describe Metalware::Commands::Hosts do

  def run_hosts(node_identifier, **options_hash)
    SpecUtils.run_command(
      Metalware::Commands::Hosts, node_identifier, **options_hash
    )
  end

  before :each do
    SpecUtils.use_mock_templater(self)
    SpecUtils.use_mock_genders(self)
    SpecUtils.use_unit_test_config(self)
  end

  context 'when called without group argument' do
    it 'appends to hosts file by default' do
      SpecUtils.expect_it_templates_for_single_node(self)
      expect(@templater).to receive(:append).with(
        '/var/lib/metalware/repo/hosts/default',
        '/etc/hosts'
      )

      run_hosts('testnode01')
    end

    it 'uses a different template if template option passed' do
      SpecUtils.expect_it_templates_for_single_node(self)
      expect(@templater).to receive(:append).with(
        '/var/lib/metalware/repo/hosts/my_template',
        '/etc/hosts'
      )

      run_hosts('testnode01', template: 'my_template')
    end

    context 'when dry-run' do
      it 'outputs what would be appended' do
        SpecUtils.expect_it_templates_for_single_node(self)
        expect(@templater).to receive(:file).with(
          '/var/lib/metalware/repo/hosts/default'
        )

        run_hosts('testnode01', dry_run: true)
      end
    end
  end

  context 'when called for group' do
    it 'appends to hosts file by default' do
      SpecUtils.expect_it_templates_for_each_node(self)

      expect(@templater).to receive(:append).thrice.with(
        '/var/lib/metalware/repo/hosts/default',
        '/etc/hosts'
      )

      run_hosts('testnodes', group: true)
    end

    context 'when dry-run' do
      it 'outputs what would be appended' do
        SpecUtils.expect_it_templates_for_each_node(self)

        expect(@templater).to receive(:file).thrice.with(
          '/var/lib/metalware/repo/hosts/default'
        )

        run_hosts('testnodes', group: true, dry_run: true)
      end
    end
  end
end
