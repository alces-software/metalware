
# frozen_string_literal: true

require 'underware/deployment_server'

module Metalware
  module CliHelper
    module DynamicDefaults
      class << self
        delegate :build_interface, to: Underware::DeploymentServer
      end
    end
  end
end
