
require 'system_command'

describe Metalware::SystemCommand do
  it 'runs the command and returns stdout' do
    expect(
      Metalware::SystemCommand.run('echo something')
    ).to eq "something\n"
  end

  it 'raises if the command fails' do
    expect{
      Metalware::SystemCommand.run('false')
    }.to raise_error Metalware::SystemCommandError
  end
end
