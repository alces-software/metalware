
require 'commander_extensions'

# These specs inspired by those in Commander gem in `spec/runner_spec.rb`.

def mock_terminal
  @input = StringIO.new
  @output = StringIO.new
  $terminal = HighLine.new @input, @output
end

def create_test_command
  command :test do |c|
    c.syntax = 'metal test ARG1 ARG2 [OPTIONAL_ARG3] [options]'
    c.description = 'test description'
    c.example 'description', 'command'
    c.option '-o', '--some-option', 'Some option that does things'
    c.when_called do |args, _options|
      format('test %s', args.join(' '))
    end
  end
  @command = command :test
end


describe CommanderExtensions do
  include CommanderExtensions::Delegates

  before :each do
    $stderr = StringIO.new
    mock_terminal
    create_test_command
  end

  describe '#command' do
    it 'instantiates a CommanderExtensions::Command' do
      expect(command(:test)).to be_instance_of(CommanderExtensions::Command)
    end
  end

  describe '#call' do
    describe 'syntax validating' do
      it 'raises if first word is not CLI name' do
        command :test do |c|
          c.syntax = 'not_metal test [options]'
        end

        expect {
          command(:test).call
        }.to raise_error(CommanderExtensions::CommandDefinitionError)
      end

      it 'raises if second word is not command name' do
        command :test do |c|
          c.syntax = 'metal not_test [options]'
        end

        expect {
          command(:test).call
        }.to raise_error(CommanderExtensions::CommandDefinitionError)
      end

      it 'raises if last word is not [options]' do
        command :test do |c|
          c.syntax = 'metal test [not_options]'
        end

        expect {
          command(:test).call
        }.to raise_error(CommanderExtensions::CommandDefinitionError)
      end
    end

    describe 'validating passed arguments against syntax' do
      it 'raises if too many arguments given' do
        expect {
          command(:test).call(['one', 'two', 'three', 'four'])
        }.to raise_error(CommanderExtensions::ArgumentsError)
      end

      it 'raises if too few arguments given' do
        expect {
          command(:test).call(['one'])
        }.to raise_error(CommanderExtensions::ArgumentsError)
      end

      it 'proceeds as normal if valid number of arguments given' do
        expect(
          command(:test).call(['one', 'two', 'three'])
        ).to eql('test one two three')
      end
    end

  end
end
