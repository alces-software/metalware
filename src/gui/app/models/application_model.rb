
# frozen_string_literal: true

class ApplicationModel
  class << self
    def config
      Rails.configuration.x.metalware_config
    end
  end

  delegate :config, to: :class
end
