
# frozen_string_literal: true

module Metalware
  class Repo
    CONFIGURE_SECTIONS = [:domain, :group, :node].freeze

    def initialize(config)
      @config = config
    end

    def configure_questions
      CONFIGURE_SECTIONS.flat_map do |section|
        configure_data[section].keys
      end.sort.uniq
    end

    private

    def configure_data
      @configure_data ||= Data.load(config.configure_file)
    end

    attr_reader :config
  end
end
