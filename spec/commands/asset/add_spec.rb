# frozen_string_literal: true

require 'commands'
require 'utils'

RSpec.describe Metalware::Commands::Asset::Add do
  it 'errors if the template does not exist' do
    expect do
      Metalware::Utils.run_command(described_class,
                                   'missing-type',
                                   'name',
                                   stderr: StringIO.new)
    end.to raise_error(Metalware::InvalidInput)
  end
end

