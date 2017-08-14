
# frozen_string_literal: true

class Configure::Questions < ApplicationModel
  class << self
    def for_domain
      configure_data[:domain]
    end

    def for_group
      configure_data[:group]
    end

    def for_node
      configure_data[:node]
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
