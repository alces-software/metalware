
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

      def build_interface
        @build_interface ||= DeploymentServer.build_interface
      end

      private

      def white_list_for_hasher
        super.push(:build_interface)
      end
    end
  end
end
