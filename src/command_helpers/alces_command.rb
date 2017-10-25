
# frozen_string_literal: true

require 'exceptions'

module Metalware
  module CommandHelpers
    module AlcesCommand
      private

      attr_reader :raw_alces_command

      def setup
        @raw_alces_command = args.first
      end

      def alces_command
        @alces_command = begin
          alces_command_alpha_numeric_only
          alces_command_split.reduce(alces) { |acc, elem| acc.send(elem) }
        end
      end

      ALCES_COMMAND_DELIM = /[\s\.]/
      ALCES_COMMAND_REGEX = \
        /\A([[:alnum:]]#{ALCES_COMMAND_DELIM}?)*[[:alnum:]]\Z/

      ALCES_COMMAND_REGEX_WARNING = <<-EOF.squish
        The alces command input can only contain upper/ lower case letters
        and numbers. It may contain spaces and periods as delimitors.
      EOF

      def alces_command_alpha_numeric_only
        match = ALCES_COMMAND_REGEX.match?(raw_alces_command)
        raise InvalidInput, ALCES_COMMAND_REGEX_WARNING unless match
      end

      def alces_command_split
        arr = raw_alces_command.split(ALCES_COMMAND_DELIM)
        arr.shift if /\A#{arr[0]}/.match?('alces')
        alces_command_replace_short_methods(arr)
        arr
      end

      def alces_command_replace_short_methods(arr)
        ['nodes', 'groups', 'domain', 'local'].each do |method|
          next unless /\A#{arr[0]}/.match?(method)
          arr.shift
          arr.unshift(method)
          break
        end
      end
    end
  end
end
