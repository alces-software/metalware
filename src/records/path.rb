# frozen_string_literal: true

require 'file_path'

module Metalware
  module Records
    class Path
      class << self
        # NOTE: Currently this method wraps the FilePath method
        # Eventually FilePath.asset will take a type input however
        # Records::Path will contain all the file globing and thus
        # will only require the name
        def asset(name, missing_error: false)
          assets.find { |path| name == File.basename(path, '.yaml') }
                .tap do |path|
            raise_missing_asset(name) if missing_error && !path
          end
        end

        def assets
          Dir.glob(FilePath.asset('**/*'))
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
