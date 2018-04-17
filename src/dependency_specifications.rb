
# frozen_string_literal: true

module Metalware
  # Class to generate reused `dependency_hash`s, for use by `Dependency` object
  # to enforce command dependencies.
  # XXX Consider moving generating of more `dependency_hash`s here.
  class DependencySpecifications
    def initialize(alces)
      @alces = alces
    end

    def for_node_in_configured_group(name)
      group = find_node(name).group
      {
        repo: ['configure.yaml'],
        configure: ['domain.yaml', "groups/#{group.name}.yaml"],
        optional: {
          configure: ["nodes/#{name}.yaml"],
        },
      }
    end

    private

    attr_reader :alces

    def find_node(name)
      node = alces.nodes.find_by_name(name)
      raise NodeNotInGendersError, "Could not find node: #{name}" unless node
      node
    end
  end
end
