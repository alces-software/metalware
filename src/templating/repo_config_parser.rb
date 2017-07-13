
require 'templating/renderer'


module Metalware
  module Templating
    module RepoConfigParser
      class << self
        def parse(base_config)
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
end
