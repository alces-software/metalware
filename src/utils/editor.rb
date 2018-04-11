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

        def open_copy(source, destination, &validation)
          name = File.basename(source, '.*')
          file = Tempfile.new(name)
          FileUtils.cp(source, file.path)
          open(file.path)
          validation.call(file) if validation
          FileUtils.cp(file.path, destination)
        ensure
          file.close
          file.unlink
        end
      end
    end
  end
end
