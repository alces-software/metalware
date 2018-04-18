
# frozen_string_literal: true

require 'alces_utils'

RSpec.describe Metalware::Commands::Power do
  include AlcesUtils

  def run_power(node_identifier, command, **options)
    AlcesUtils.redirect_std(:stdout) do
      Metalware::Utils.run_command(
        Metalware::Commands::Power, node_identifier, command, **options
      )
    end[:stdout].read
  end

  describe 'when run on bare metal' do
    let(:node_names) { ['node01', 'node02', 'node03'] }
    let(:group) { 'nodes' }
    let(:namespace_config) do
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
    before do
      with_args = [/\Anodeattr.*/, an_instance_of(Hash)]
      allow(Metalware::SystemCommand).to \
        receive(:run).with(*with_args).and_call_original
    end

    describe 'when run for node' do
      it 'runs appropriate ipmi command for given command and node' do
        expect(Metalware::SystemCommand).to receive(:run).once.with(
          <<-EOF.squish
            ipmitool -H node01.bmc -I lanplus -U bmcuser -P
            bmcpassword chassis power on
          EOF
        )

        run_power('node01', 'on')
      end
    end

    describe 'when run for group' do
      it 'runs appropriate ipmi command followed by sleep for each node' do
        node_names.each do |name|
          expect(Metalware::SystemCommand).to receive(:run).with(
            <<-EOF.squish
              ipmitool -H #{name}.bmc -I lanplus -U bmcuser -P
              bmcpassword chassis power on
            EOF
          ).ordered.and_return('output123')
        end

        output = run_power('nodes', 'on', gender: true, sleep: 0.5)

        node_names.each do |name|
          expect(output).to include("#{name}: output123")
        end
      end

      it 'does not error when individual ipmi commands error' do
        allow(
          Metalware::SystemCommand
        ).to receive(:run)
          .with(/ipmitool -H node01/)
          .once
          .and_raise(Metalware::SystemCommandError, 'error123')
        allow(
          Metalware::SystemCommand
        ).to receive(:run)
          .twice
          .with(/ipmitool -H node0[23]/)
          .and_return('output123')

        expect do
          output = run_power('nodes', 'on', gender: true)
          lines = output.lines.map(&:strip)

          expect(lines).to eq([
                                'node01: error123',
                                'node02: output123',
                                'node03: output123',
                              ])
        end.not_to raise_error
      end
    end
  end
end
