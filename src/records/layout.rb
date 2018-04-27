# frozen_string_literal: true

require 'records/record'

module Metalware
  module Records
    class Layout < Record
      class << self
        def paths
          Dir.glob(FilePath.layout('[a-z]*', '*'))
        end
      end
    end
  end
end
