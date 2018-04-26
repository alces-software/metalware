# frozen_string_literal: true

require 'file_path'

module Metalware
  module Records
    class Asset
      TYPES = begin
        Dir.glob(Metalware::FilePath.asset_type('*')).map do |path|
          File.basename(path, '.yaml')
        end
      end.freeze

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
          if TYPES.include?(name) || TYPES.map(&:pluralize).include?(name)
            false
          else
            !path(name)
          end
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
