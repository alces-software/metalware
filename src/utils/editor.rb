# frozen_string_literal: true

require 'utils'

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
      end
    end
  end
end
