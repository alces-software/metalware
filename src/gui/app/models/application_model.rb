
# frozen_string_literal: true

class ApplicationModel
  class << self
    def config
      Rails.configuration.x.metalware_config
    end

    def file_path
      @file_path ||= Metalware::FilePath.new(config)
    end
  end

  delegate :config, :file_path, to: :class
end
