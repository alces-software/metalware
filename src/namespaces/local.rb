
# frozen_string_literal: true

require 'build_methods'
require 'file_path'

module Metalware
  module Namespaces
    class Local < Node
      class << self
        def create(*args)
          new(*args)
        end

        def new(*args)
          super
        end
      end

      def build_method
        BuildMethods::Local
      end

      def build_complete_path
        @build_complete_path ||= FilePath.new(metal_config)
                                         .build_complete('local')
      end
    end
  end
end
