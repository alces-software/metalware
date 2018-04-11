# frozen_string_literal: true

require 'utils'
require 'fileutils'
require 'tempfile'

module Metalware
  module Utils
    class Editor
      DEFAULT_EDITOR = 'vi'

      class << self
        def open(file)
          SystemCommand.no_capture("#{editor} #{file}")
        end

        def editor
          ENV['VISUAL'] || ENV['EDITOR'] || DEFAULT_EDITOR
        end

        def open_copy(source, destination, &b)
          name = File.basename(source, '.*')
          file = Tempfile.new(name)
          FileUtils.cp(source, file.path)
          open(file.path)
          raise_error_if_validation_fails(file.path, &b) if b
          FileUtils.cp(file.path, destination)
        ensure
          file.close
          file.unlink
        end

        private

        def raise_error_if_validation_fails(path, &validation)
          return if validation.call(path)
          raise ValidationFailure, <<-EOF.squish
            The edited file is invalid
          EOF
        end
      end
    end
  end
end
