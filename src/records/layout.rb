# frozen_string_literal: true

require 'records/record'

module Metalware
  module Records
    class Layout < Record
      class << self
        def paths
          Dir.glob(FilePath.layout('[a-z]*', '*'))
        end

        def record_dir
          FilePath.layout_dir
        end
      end
    end
  end
end
