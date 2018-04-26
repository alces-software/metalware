# frozen_string_literal: true

require 'file_path'

module Metalware
  module Records
    class Asset
      class << self
        def path(name, missing_error: false)
          paths.find { |path| name == File.basename(path, '.yaml') }
               .tap do |path|
            raise_missing_asset(name) if missing_error && !path
          end
        end

        def paths
          Dir.glob(FilePath.asset('[a-z]*', '*'))
        end

        def available?(name)
          !path(name)
        end

        private

        def raise_missing_asset(name)
          raise MissingRecordError, <<-EOF.squish
            The "#{name}" asset does not exist
          EOF
        end
      end
    end
  end
end
