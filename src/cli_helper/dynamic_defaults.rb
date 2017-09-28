
# frozen_string_literal: true

module Metalware
  module CliHelper
    module DynamicDefaults
      class << self
        delegate :build_interface, to: DeploymentServer
      end
    end
  end
end
