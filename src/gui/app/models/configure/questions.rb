
# frozen_string_literal: true

class Configure::Questions < ApplicationModel
  class << self
    def for_domain
      Metalware::Configurator.for_domain(config: config).questions
    end

    def for_group(group_name)
      Metalware::Configurator.for_group(
        group_name, config: config
      ).questions
    end

    def for_node(node_name)
      node = Metalware::Node.new(config, node_name)
      Metalware::Configurator.for_node(
        node, config: config
      ).questions
    end

    private

    def configure_data
      loader.configure_data
    end

    def loader
      Metalware::Validation::Loader.new(config)
    end
  end
end
