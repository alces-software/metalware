
require 'commander'


module CommanderExtensions
  class ArgumentsError < StandardError; end
  class CommandDefinitionError < StandardError; end


  module Delegates
    include Commander::Delegates

    # Method analagous to `Commander::Delegates#command`, but instantiates our
    # `Command` instead of `Commander::Command`.
    def command(name, &block)
      yield add_command(Command.new(name)) if block
      Commander::Runner.instance.commands[name.to_s]
    end
  end


  class Command < Commander::Command
    def run(*args)
      super(*args)
    rescue ArgumentsError => error
      abort "#{error}. Usage: #{syntax}"
    end

    def call(args = [])
      # Use defined syntax to validate how many args this command can be
      # passed.
      validate_syntax!
      validate_correct_number_of_args!(args)

      # Invoke original method.
      super(args)
    end

    private

    def validate_syntax!
      cli_name = 'metal'

      first_word = syntax_parts.first
      second_word = syntax_parts[1]
      last_word = syntax_parts.last

      if first_word != cli_name
        fail CommandDefinitionError,
          "First word in 'syntax' should be CLI name ('#{cli_name}'), got '#{first_word}'"
      elsif second_word != name
        fail CommandDefinitionError,
          "Second word in 'syntax' should be command name ('#{name}'), got '#{second_word}'"
      elsif last_word != '[options]'
        fail CommandDefinitionError,
          "Last word in 'syntax' should be '[options]', got '#{last_word}'"
      end
    end

    def validate_correct_number_of_args!(args)
      if too_many_args?(args)
        fail ArgumentsError, "Too many arguments given"
      elsif too_few_args?(args)
        fail ArgumentsError, "Too few arguments given"
      end
    end

    def syntax_parts
      syntax.split
    end

    def arguments_syntax_parts
      syntax_parts[2...(syntax_parts.length - 1)]
    end

    def total_arguments
      arguments_syntax_parts.length
    end

    def optional_arguments
      arguments_syntax_parts.select do |part|
        part[0] == '[' && part[-1] == ']'
      end.length
    end

    def required_arguments
      total_arguments - optional_arguments
    end

    def too_many_args?(args)
      args.length > total_arguments
    end

    def too_few_args?(args)
      args.length < required_arguments
    end
  end

end
