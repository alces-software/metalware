
# frozen_string_literal: true

module Metalware
  module CliHelper
    module DynamicDefaults
      class << self
        def build_interface
          DeploymentServer.build_interface
        end
      end
    end
  end
end
