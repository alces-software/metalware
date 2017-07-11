
require 'yaml'


module Metalware
  module Data

    class << self
      def load(data_file)
        if File.file? data_file
          YAML.load_file(data_file) || {}
        else
          {}
        end.deep_transform_keys { |k| k.to_sym }
      end

      def dump(data_file, data)
        yaml = data.deep_transform_keys { |k| k.to_s }.to_yaml
        File.write(data_file, yaml)
      end
    end

  end
end
