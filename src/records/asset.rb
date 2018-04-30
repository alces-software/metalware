# frozen_string_literal: true

require 'records/record'

module Metalware
  module Records
    class Asset < Record
      class << self
        def paths
          Dir.glob(FilePath.asset('[a-z]*', '*'))
        end

        def record_dir
          FilePath.asset_dir
        end
      end
    end
  end
end
