# frozen_string_literal: true

require 'utils'

module Metalware
  module Utils
    class Editor
      class << self
        def open
          
        end

        def editor
          if ENV['EDITOR'].present?
            ENV['EDITOR']
          else
            'vi'
          end
        end
      end
    end
  end
end
