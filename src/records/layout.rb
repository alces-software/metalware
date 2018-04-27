# frozen_string_literal: true

require 'records/record'

module Metalware
  module Records
    class Layout < Record
      class << self
        def paths
          Dir.glob(FilePath.layout('[a-z]*', '*'))
        end

        def base_path(base_name)
          if self::TYPES.include?(base_name)
            FilePath.asset_type(base_name)
          elsif path(base_name)
            type = File.basename(File.dirname(path(base_name))).pluralize
            FilePath.layout(type, base_name)
          else
            raise InvalidInput, <<-EOF.squish
              There is no '#{base_name}' type or layout
            EOF
          end
        end
      end
    end
  end
end
