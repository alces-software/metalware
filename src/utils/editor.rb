# frozen_string_literal: true

require 'utils'

module Metalware
  module Utils
    class Editor
      class << self
        def open(file)
          SystemCommand.run("#{editor} #{file}")
        end

        def editor
          ENV['VISUAL'] || ENV['EDITOR'] || 'vi'
        end
      end
    end
  end
end
