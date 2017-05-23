
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
      command_syntax = command_syntax_parts.join(' ')

      if syntax_parts.first != cli_name
        fail CommandDefinitionError,
          "First word in 'syntax' should be CLI name ('#{cli_name}'), got '#{syntax_parts.first}'"
      elsif command_syntax != name
        fail CommandDefinitionError,
          "After CLI name in syntax should come command name(s) ('#{name}'), got '#{command_syntax}'"
      elsif syntax_parts.last != '[options]'
        fail CommandDefinitionError,
          "Last word in 'syntax' should be '[options]', got '#{syntax_parts.last}'"
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

    def command_syntax_parts
      number_command_words = name.split.length
      syntax_parts[1, number_command_words]
    end

    def arguments_syntax_parts
      args_start_index = 1 + command_syntax_parts.length
      args_end_index = syntax_parts.length - 1
      syntax_parts[args_start_index...args_end_index]
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
