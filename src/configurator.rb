
require 'active_support/core_ext/hash'


module Metalware
  class Configurator
    def initialize(highline:, configure_file:, questions:, answers_file:)
      @highline = highline
      @configure_file = configure_file
      @questions_section = questions
      @answers_file = answers_file

      @questions = load_questions
    end

    def configure
      answers = ask_questions
      save_answers(answers)
    end

    private

    attr_reader :highline,
      :configure_file,
      :questions_section,
      :answers_file,
      :questions

    def load_questions
      @questions = YAML.load_file(configure_file).
        with_indifferent_access[questions_section].
        map{ |identifier, properties| create_question(identifier, properties) }
    end

    def ask_questions
      questions.map do |question|
        answer = question.ask(highline)
        [question.identifier, answer]
      end.to_h
    end

    def save_answers(answers)
      File.open(answers_file, 'w') do |f|
        f.write(YAML.dump(answers))
      end
    end

    def create_question(identifier, properties)
      Question.new(
        identifier: identifier,
        properties: properties,
        configure_file: configure_file,
        questions_section: questions_section
      )
    end

    class Question
      VALID_TYPES = [:boolean, :choice, :integer, :string]

      attr_reader :identifier, :question, :type, :choices

      def initialize(identifier:, properties:, configure_file:, questions_section:)
        @identifier = identifier
        @question = properties[:question]
        @choices = properties[:choices]
        @type = type_for(
          properties[:type],
          configure_file: configure_file,
          questions_section: questions_section
        )
      end

      def ask(highline)
        case type
        when :boolean
          highline.agree(question)
        when :choice
          highline.choose(*choices) do |menu|
            menu.prompt = question
          end
        when :integer
          highline.ask(question, Integer)
        else
          highline.ask(question)
        end
      end

      private

      def type_for(value, configure_file:, questions_section:)
        value = value&.to_sym
        if value.nil?
          :string
        elsif valid_type?(value)
          value
        else
          message = \
            "Unknown question type '#{value}' for " +
            "#{questions_section}.#{identifier} in #{configure_file}"
          raise UnknownQuestionTypeError, message
        end
      end

      def valid_type?(value)
        VALID_TYPES.include?(value)
      end
    end

  end
end
