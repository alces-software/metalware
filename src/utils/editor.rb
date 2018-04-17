# frozen_string_literal: true

require 'utils'
require 'fileutils'
require 'tempfile'
require 'highline'

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
            FileUtils.cp(path, destination) if File.exist?(path)
          end
        end

        private

        def create_temp_file(name, content)
          file = Tempfile.new(name)
          file.write(content)
          file.flush
          yield file.path
        ensure
          file.close
          file.unlink
        end

        def raise_if_validation_fails(path, &validator)
          return if yield path
          prompt_user
          open(path)
          raise_if_validation_fails(path, &validator) if validator
        end

        def prompt_user
          cli = HighLine.new
          if cli.agree(<<-EOF.squish
                The file is invalid and will be discarded,
                would you like to reopen? (y/n)
              EOF
                      )
          else
            raise ValidationFailure, <<-EOF.squish
              Failed to edit file, changes have been discarded
            EOF
          end
        end
      end
    end
  end
end
