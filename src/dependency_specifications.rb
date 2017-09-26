
# frozen_string_literal: true

module Metalware
  # Class to generate reused `dependency_hash`s, for use by `Dependency` object
  # to enforce command dependencies.
  # XXX Consider moving generating of more `dependency_hash`s here.
  class DependencySpecifications
    def initialize(config)
      @config = config
    end

    def for_node_in_configured_group(node_name)
      primary_group = configured_primary_group_for_node(node_name)
      {
        repo: ['configure.yaml'],
        configure: ['domain.yaml', "groups/#{primary_group}.yaml"],
        optional: {
          configure: ["nodes/#{node_name}.yaml"],
        },
      }
    end

    private

    attr_reader :config

    def configured_primary_group_for_node(node_name)
      Node.new(
        config, node_name, should_be_configured: true
      ).primary_group
    end
  end
end
