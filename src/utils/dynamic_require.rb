
# frozen_string_literal: true

module Metalware
  module Utils
    class DynamicRequire
      class << self
        # Recursively requires all ruby files in the require_directory relative
        # to the calling file's directory
        def relative(require_directory)
          require_files(require_directory).each do |file|
            require file
          end
        end

        private

        def require_files(require_directory)
          # Sorting files to require is needed so that we require files in a
          # deterministic order (globbing by itself is non-deterministic), to
          # prevent issues as described from
          # https://alces.slack.com/archives/C5FL99R89/p1517402592000215.
          Dir[File.join(calling_file_dir, require_directory, '**/*.rb')].sort
        end

        def calling_file_dir
          File.dirname(calling_file_path)
        end

        # Finds the file path of the calling file
        def calling_file_path
          caller.each do |call|
            # Filters line position from caller string
            path = call.match(/\A(?:(?!:).)*/)[0]
            return path unless path == __FILE__
          end
        end
      end
    end
  end
end
