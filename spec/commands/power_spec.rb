
# frozen_string_literal: true

require 'alces_utils'

RSpec.describe Metalware::Commands::Power do
  include AlcesUtils

  def run_power(node_identifier, command, **options)
    AlcesUtils.redirect_std(:stdout) do
      Metalware::Utils.run_command(
        Metalware::Commands::Power, node_identifier, command, **options
      )
    end
  end

  describe 'when run on bare metal' do
    let :node_names { ['node01', 'node02', 'node03'] }
    let :group { 'nodes' }
    let :namespace_config do
      {
        networks: {
          bmc: {
            defined: true,
            bmcuser: 'bmcuser',
            bmcpassword: 'bmcpassword',
          },
        },
      }
    end

    AlcesUtils.mock self, :each do
      config(mock_group(group), namespace_config)
      node_names.each do |node|
        config(mock_node(node, group), namespace_config)
      end
    end

    # Allow the system command to receive `nodeattr` commands
    before :each do
      with_args = [/\Anodeattr.*/, an_instance_of(Hash)]
      allow(Metalware::SystemCommand).to \
        receive(:run).with(*with_args).and_call_original
    end

    describe 'when run for node' do
      it 'runs appropriate ipmi command for given command and node' do
        expect(Metalware::SystemCommand).to receive(:run).once.with(
          'ipmitool -H node01.bmc -I lanplus -U bmcuser -P bmcpassword chassis power on'
        )

        run_power('node01', 'on')
      end
    end

    describe 'when run for group' do
      it 'runs appropriate ipmi command followed by sleep for each node' do
        node_names.each do |name|
          expect(Metalware::SystemCommand).to receive(:run).with(
            "ipmitool -H #{name}.bmc -I lanplus -U bmcuser -P bmcpassword chassis power on"
          ).ordered
        end

        run_power('nodes', 'on', gender: true, sleep: 0.5)
      end
    end
  end
end
