
require 'command_helpers/base_command'
require 'alces_utils'

RSpec.describe Metalware::MetalLog do
  describe '#warn' do
    # MetalLog receives `strict`/`quiet` from the command, so need to create a
    # 'real' command to use in tests.
    class Metalware::Commands::TestCommand < Metalware::CommandHelpers::BaseCommand
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

    after :each do
      # Reset global options passed to MetalLog by command.
      Metalware::MetalLog.strict = false
      Metalware::MetalLog.quiet = false
    end

    it 'gives warning output by default' do
      expect(Metalware::Output).to receive(:warning).with('warning: message')

      run_test_command
    end

    it 'does not give warning and raises when --strict passed' do
      expect_any_instance_of(Logger).not_to receive(:warn)
      expect(Metalware::Output).not_to receive(:warning).with('warning: message')

      expect do
        run_test_command(strict: true)
      end.to raise_error(Metalware::StrictWarningError)
    end

    it 'does not give warning output when --quiet passed' do
      expect(Metalware::Output).not_to receive(:warning).with('warning: message')

      run_test_command(quiet: true)
    end

    [true, false].each do |quiet|
      it "logs warning to file when quiet=#{quiet}" do
        expect_any_instance_of(Logger).to receive(:warn).with('message')

        run_test_command(quiet: quiet)
      end
    end
  end
end
