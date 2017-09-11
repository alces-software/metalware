
# frozen_string_literal: true
require 'constants'

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

    def configure_data
      @configure_data ||= Data.load(config.configure_file)
    end

    def configure_data_sections
      Constants::CONFIGURE_SECTIONS.map { |section| configure_data[section] }
    end

    attr_reader :config
  end
end
