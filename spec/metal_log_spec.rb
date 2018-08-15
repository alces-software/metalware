
# frozen_string_literal: true

require 'command_helpers/base_command'
require 'alces_utils'

RSpec.describe Metalware::MetalLog do
  describe '#warn' do
    # MetalLog receives `strict`/`quiet` from the command, so need to create a
    # 'real' command to use in tests.
    base_command = Metalware::CommandHelpers::BaseCommand
    class Metalware::Commands::TestCommand < base_command
      def run
        Metalware::MetalLog.warn 'message'
      end
    end

    def run_test_command(**options)
      AlcesUtils.redirect_std(:stderr) do
        Metalware::Utils.run_command(
          Metalware::Commands::TestCommand, **options
        )
      end
    end

    let!(:output) do
      class_spy(Metalware::Output).as_stubbed_const
    end

    let(:test_warning) { 'warning: message' }

    after do
      # Reset global options passed to MetalLog by command.
      described_class.strict = false
      described_class.quiet = false
    end

    it 'gives warning output by default' do
      run_test_command
      expect(output).to \
        have_received(:warning).with(test_warning)
    end

    it 'only issues the warning once' do
      run_test_command
      run_test_command
      expect(output).to have_received(:warning).once
    end

    it 'does not give warning and raises when --strict passed' do
      expect_any_instance_of(Logger).not_to receive(:warn)
      expect do
        run_test_command(strict: true)
      end.to raise_error(Metalware::StrictWarningError)

      expect(output).not_to \
        have_received(:warning).with(test_warning)
    end

    it 'does not give warning output when --quiet passed' do
      run_test_command(quiet: true)
      expect(output).not_to \
        have_received(:warning).with(test_warning)
    end

    [true, false].each do |quiet|
      it "logs warning to file when quiet=#{quiet}" do
        expect_any_instance_of(Logger).to receive(:warn).with('message')

        run_test_command(quiet: quiet)
      end
    end
  end
end
