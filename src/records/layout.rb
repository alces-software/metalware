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

        def type_or_layout(name)
          if Records::Asset::TYPES.include?(name)
            OpenStruct.new(
              type: name,
              path: FilePath.asset_type(name)
            )
          elsif (path = Records::Layout.path(name))
            OpenStruct.new(
              type: Records::Layout.type_from_path(path),
              path: path
            )
          end
        end
      end
    end
  end
end
