
require 'templating/renderer'


module Metalware
  module Templating
    class RepoConfigParser
      private_class_method :new

      class << self

        # XXX get rid of handling `additional_parameters`? And just take what
        # we need.
        def parse_for_node(node_name:, config:, additional_parameters: {})
          new(
            node_name: node_name,
            config: config,
            additional_parameters: additional_parameters
          ).parse
        end
      end

      def parse
        current_parsed_config = base_config
        current_config_string = current_parsed_config.to_s
        previous_config_string = nil
        count = 0

        # Loop through the config and recursively parse any config values which
        # contain ERB, until the parsed config is not changing or we have
        # exceeded the maximum number of passes to make.
        while previous_config_string != current_config_string
          count += 1
          if count > Constants::MAXIMUM_RECURSIVE_CONFIG_DEPTH
            raise RecursiveConfigDepthExceededError
          end

          previous_config_string = current_config_string
          current_parsed_config = perform_config_parsing_pass(current_parsed_config)
          current_config_string = current_parsed_config.to_s
        end

        create_template_parameters(current_parsed_config)
      end

      private

      attr_reader :node_name, :metalware_config, :additional_parameters

      def initialize(node_name:, config:, additional_parameters:)
        @node_name = node_name
        @metalware_config = config
        @additional_parameters = additional_parameters
      end

      def node
        @node ||= Node.new(metalware_config, node_name)
      end

      # The merging of the raw combined config files, any additional passed
      # values, and the magic `alces` namespace; this is the config prior to
      # parsing any nested ERB values.
      # XXX Get rid of merging in `passed_hash`? This will cause an issue if a
      # config specifies a value with the same name as something in the
      # `passed_hash`, as it will overshadow it, and we don't actually want to
      # support this any more.
      def base_config
        @base_config ||= node.raw_config
          .merge(additional_parameters)
          .merge(alces: magic_namespace)
      end

      def magic_namespace
        MissingParameterWrapper.new(MagicNamespace.new(
          config: metalware_config,
          node: node,
          **magic_parameters
        ))
      end

      def magic_parameters
        additional_parameters.select { |k,v|
          [:firstboot, :files].include?(k) && !v.nil?
        }
      end

      def perform_config_parsing_pass(current_parsed_config)
        current_parsed_config.map do |k,v|
          [k, parse_config_value(v, current_parsed_config)]
        end.to_h
      end

      def parse_config_value(value, current_parsed_config)
        case value
        when String
          parameters = create_template_parameters(current_parsed_config)
          Renderer.replace_erb(value, parameters)
        when Hash
          value.map do |k,v|
            [k, parse_config_value(v, current_parsed_config)]
          end.to_h
        else
          value
        end
      end

      def create_template_parameters(config)
        MissingParameterWrapper.new(IterableRecursiveOpenStruct.new(config))
      end
    end
  end
end