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

        def open_copy(source, destination)
          file = Tempfile.new(['asset-copy', '.yaml'], destination)
          begin
            FileUtils.cp source file.path
            open(file)
          ensure
            file.close
            file.unlink 
          end
        end
      end
    end
  end
end
