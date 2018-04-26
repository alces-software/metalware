# frozen_string_literal: true

require 'file_path'

module Metalware
  module Records
    class Path
      class << self
        def asset(name, missing_error: false)
          assets.find { |path| name == File.basename(path, '.yaml') }
                .tap do |path|
            raise_missing_asset(name) if missing_error && !path
          end
        end

        def assets
          Dir.glob(FilePath.asset('[a-z]*', '*'))
        end

        def avaliable?(name)
          !asset(name)
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
