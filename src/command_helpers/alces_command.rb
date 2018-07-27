
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
          alces_command_split.reduce(alces) { |acc, elem| acc.send(elem) }
        end
      end

      ALCES_COMMAND_DELIM = /[\.]/
      ALCES_COMMAND_REGEX = \
        /\A([[:alnum:]]#{ALCES_COMMAND_DELIM}?)*[[:alnum:]]\Z/

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
