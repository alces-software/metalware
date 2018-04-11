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

        def open_copy(source, destination, &validator)
          name = File.basename(source, '.*')
          create_temp_file(name, File.read(source)) do |path|
            open(path)
            raise_if_validation_fails(path, &validator) if validator
            FileUtils.cp(path, destination)
          end
        end

        private

        def create_temp_file(name, content)
          file = Tempfile.new(name)
          file.write(content)
          yield file.path
        ensure
          file.close
          file.unlink
        end

        def raise_if_validation_fails(path)
          return if yield path
          raise ValidationFailure, <<-EOF.squish
            The edited file is invalid
          EOF
        end
      end
    end
  end
end
