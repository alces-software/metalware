
module Metalware
  module Utils

    class << self
      # Load YAML from `file`, or empty hash if file does not exist or does not
      # contain YAML.
      def safely_load_yaml(file)
        if File.file? file
          YAML.load_file(file) || {}
        else
          {}
        end
      end
    end

  end
end
