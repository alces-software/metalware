
# frozen_string_literal: true

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

  context 'when run on bare metal' do
    # XXX The setup for these tests is duplicated from those for power; should
    # DRY this up.

    let :node_names { ['node01', 'node02', 'node03'] }
    let :group { 'nodes' }
    let :gender { 'my_super_awesome_gender' }
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
      node_names.each do |name|
        node = mock_node(name, group, gender)
        config(node, namespace_config)
      end
    end

    def expect_ipmi_cmd(name)
      cmd = <<~EOF.squish
        ipmitool -H #{name}.bmc -I lanplus -U bmcuser -P bmcpassword sel
        list
      EOF
      expect(Metalware::SystemCommand).to receive(:run).with(cmd).ordered
    end

    # Allow the system command to receive `nodeattr` commands
    before :each do
      with_args = [/\Anodeattr.*/, an_instance_of(Hash)]
      allow(Metalware::SystemCommand).to \
        receive(:run).with(*with_args).and_call_original
    end

    context 'when run for node' do
      it 'runs given ipmi command on node' do
        expect_ipmi_cmd('node01')
        run_ipmi('node01', 'sel list')
      end
    end

    shared_examples 'runs on each node' do
      it 'runs given ipmi command on each node' do
        node_names.each { |name| expect_ipmi_cmd(name) }
        run_ipmi(test_gender, 'sel list', gender: true)
      end
    end

    context 'when run for group' do
      let :test_gender { group }
      include_examples 'runs on each node'
    end
  end
end
