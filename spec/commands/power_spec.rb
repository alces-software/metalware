
require 'alces_utils'

RSpec.describe Metalware::Commands::Power do
  def run_power(node_identifier, command, **options)
    AlcesUtils.redirect_std(:stdout) do
      Metalware::Utils.run_command(
        Metalware::Commands::Power, node_identifier, command, **options
      )
    end
  end

  describe 'when run on bare metal' do
    let :node_names { ['node01', 'node02', 'node03'] }

    before :each do
      # XXX Factor out this setup in a reusable but still clear form. An
      # alternative approach would be to use AlcesUtils, but this seems
      # convoluted and unclear and mocks too many things for me to trust it.
      # This approach is at least explicit about the preconditions which must
      # be met before this command can be run.

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

        run_power('nodes', 'on', group: true, sleep: 0.5)
      end
    end
  end
end
