
# frozen_string_literal: true

require 'json'

module Metalware
  module Commands
    class ViewConfig < CommandHelpers::BaseCommand
      def setup(args, _options)
        @node_name = args.first
      end

      def run
        puts templating_config_json
      end

      private

      attr_reader :node_name

      def templating_config_json
        JSON.pretty_generate(templater.config.to_h)
      end

      def templater
        Metalware::Templater.new(config, nodename: node_name)
      end
    end
  end
end
