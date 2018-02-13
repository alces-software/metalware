
require 'alces_utils'

RSpec.describe Metalware::Commands::Ipmi do
  include AlcesUtils

  def run_ipmi(node_identifier, command, **options)
    AlcesUtils.redirect_std(:stdout) do
      Metalware::Utils.run_command(
        Metalware::Commands::Ipmi, node_identifier, command, **options
      )
    end
  end

  describe 'when run on bare metal' do
    # XXX The setup for these tests is duplicated from those for power; should
    # DRY this up.

    let :node_names { ['node01', 'node02', 'node03'] }
    let :group { 'nodes' }
    let :node_config do
      {
        networks: {
          bmc: {
            defined: true,
            bmcuser: 'bmcuser',
            bmcpassword: 'bmcpassword',
          }
        }
      }
    end

    AlcesUtils.mock self, :each do
      mock_group(group)
      node_names.each do |node|
        mock_node(node, group)
        config(alces.node, node_config)
      end
    end

    # Allow the system command to receive `nodeattr` commands
    before :each do
      with_args = [/\Anodeattr.*/, an_instance_of(Hash)]
      allow(Metalware::SystemCommand).to \
        receive(:run).with(*with_args).and_call_original
    end

    describe 'when run for node' do
      it 'runs given ipmi command on node' do
        expect(Metalware::SystemCommand).to receive(:run).once.with(
          'ipmitool -H node01.bmc -I lanplus -U bmcuser -P bmcpassword sel list'
        )

        run_ipmi('node01', 'sel list')
      end
    end

    describe 'when run for group' do
      it 'runs given ipmi command on each node' do
        node_names.each do |name|
          expect(Metalware::SystemCommand).to receive(:run).with(
            "ipmitool -H #{name}.bmc -I lanplus -U bmcuser -P bmcpassword sel list"
          ).ordered
        end

        run_ipmi('nodes', 'sel list', gender: true)
      end
    end
  end
end
