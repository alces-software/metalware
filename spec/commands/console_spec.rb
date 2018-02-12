
require 'alces_utils'

RSpec.describe Metalware::Commands::Console do
  def run_console(node_name, **options)
    AlcesUtils.redirect_std(:stdout) do
      Metalware::Utils.run_command(
        Metalware::Commands::Console, node_name, **options
      )
    end
  end

  describe 'when run on bare metal' do
    # XXX The setup for these tests is duplicated from those for power;
    # should DRY this up.

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
      it 'runs console info then activate commands for node' do
        expect(Metalware::SystemCommand).to receive(:run).with(
          "ipmitool -H node01 -U bmcuser -P bmcpassword -e '&' -I lanplus sol info"
        ).ordered.and_return(true)
        expect_any_instance_of(
          Metalware::Commands::Console
        ).to receive(:system).with(
          "ipmitool -H node01 -U bmcuser -P bmcpassword -e '&' -I lanplus sol activate"
        )

        run_console('node01')
      end
    end
  end
end

