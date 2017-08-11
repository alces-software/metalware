
# frozen_string_literal: true

class Configure::Questions < ApplicationModel
  class << self
    def for_domain
      configure_data[:domain]
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
