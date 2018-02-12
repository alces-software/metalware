
require 'alces_utils'

RSpec.describe Metalware::Commands::Ipmi do
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

    before :each do
      allow(
        Metalware::NodeattrInterface
      ).to receive(:groups_for_node).and_return(['nodes'])
      allow(
        Metalware::NodeattrInterface
      ).to receive(:all_nodes).and_return(node_names)
      allow(
        Metalware::NodeattrInterface
      ).to receive(:nodes_in_group).and_return(node_names)

      FileSystem.root_setup do |fs|
        fs.with_minimal_repo

        domain_config_path = Metalware::FilePath.domain_config
        fs.create(domain_config_path)

        fs.setup do
          Metalware::Data.dump(domain_config_path, {
            networks: {
              bmc: {
                defined: true,
                bmcuser: 'bmcuser',
                bmcpassword: 'bmcpassword',
              }
            }
          })

          Metalware::Utils.run_command(
            Metalware::Commands::Configure::Group, 'nodes'
          )
        end
      end
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

        run_ipmi('nodes', 'sel list', group: true)
      end
    end
  end
end
