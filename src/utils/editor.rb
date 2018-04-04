# frozen_string_literal: true

require 'utils'

module Metalware
  module Utils
    class Editor
      class << self
        def open
          
        end

        def editor
          ENV['VISUAL'] || ENV['EDITOR'] || 'vi'
        end
      end
    end
  end
end
