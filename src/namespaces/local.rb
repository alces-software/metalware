
# frozen_string_literal: true

require 'build_methods'
require 'deployment_server'

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

      def build_interface
        @build_interface ||= DeploymentServer.build_interface
      end
    end
  end
end
