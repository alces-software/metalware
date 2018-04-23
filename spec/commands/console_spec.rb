
# frozen_string_literal: true

require 'alces_utils'

RSpec.describe Metalware::Commands::Console do
  include AlcesUtils

  def run_console(node_name, **options)
    AlcesUtils.redirect_std(:stdout) do
      Metalware::Utils.run_command(
        Metalware::Commands::Console, node_name, **options
      )
    end
  end

  describe 'when run on bare metal' do
    let(:node_name) { 'node01' }
    let(:node_config) do
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
      config(mock_node(node_name), node_config)
    end

    describe 'when run for node' do
      it 'runs console info then activate commands for node' do
        expect(Metalware::SystemCommand).to receive(:run).with(
          <<-EOF.squish
            ipmitool -H node01.bmc -I lanplus -U bmcuser -P bmcpassword -e
            '&' sol info
          EOF
        ).ordered.and_return(true)
        expect_any_instance_of(
          described_class
        ).to receive(:system).with(
          <<-EOF.squish
            ipmitool -H node01.bmc -I lanplus -U bmcuser -P bmcpassword -e
            '&' sol activate
          EOF
        )

        run_console('node01')
      end
    end
  end
end
