
# frozen_string_literal: true

require 'constants'
require 'validation/loader'

module Metalware
  class Repo
    def initialize(config)
      @config = config
    end

    def configure_questions
      configure_data_sections.reduce(:merge)
    end

    def configure_question_identifiers
      configure_questions.keys.sort.uniq
    end

    private

    def loader
      @loader ||= Validation::Loader.new(config)
    end

    def configure_data
      @configure_data ||= loader.configure_data
    end

    def configure_data_sections
      Constants::CONFIGURE_SECTIONS.map { |section| configure_data[section] }
    end

    attr_reader :config
  end
end
