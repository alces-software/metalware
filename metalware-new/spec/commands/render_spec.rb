
require 'timeout'

require 'commands/render'
require 'node'
require 'spec_utils'
require 'yaml'


describe Metalware::Commands::Render do
  context 'and with --strict option' do
    it 'raises StrictWarningError when a parameter is missing' do
      conf = YAML::load_file(File.join(__dir__,"../fixtures/configs/unit-test.yaml"))
      expect {
        SpecUtils.run_command(
          Metalware::Commands::Render, "a", {strict: true}
        )
      }.to raise_error(Metalware::StrictWarningError)
    end
  end
end
