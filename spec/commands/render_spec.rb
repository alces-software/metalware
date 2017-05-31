
require 'timeout'

require 'commands/render'
require 'node'
require 'spec_utils'
require 'config'

RSpec.describe Metalware::Commands::Render do
  before :each do
    SpecUtils.use_unit_test_config(self)
  end

  context 'and with --strict option' do
    xit 'raises StrictWarningError when a parameter is missing' do
      config = Metalware::Config.new(nil)
      path = File.join(config.repo_path, "dhcp/default")
      expect {
        SpecUtils.run_command(
          Metalware::Commands::Render, path, {strict: true}
        )
      }.to raise_error(Metalware::StrictWarningError)
    end
  end
end
