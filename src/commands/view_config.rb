
# frozen_string_literal: true

require 'json'

module Metalware
  module Commands
    class ViewConfig < CommandHelpers::BaseCommand
      def setup(args, _options)
        @node_name = args.first
      end

      def run
        templater = Metalware::Templater.new(Metalware::Config.new, nodename: node_name)
        puts JSON.pretty_generate(templater.config.to_h)
      end

      private

      attr_reader :node_name
    end
  end
end
