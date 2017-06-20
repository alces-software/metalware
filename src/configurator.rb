
require 'active_support/core_ext/hash'


module Metalware
  class Configurator
    def initialize(highline:, configure_file:, questions:, answers_file:)
      @highline = highline
      @answers_file = answers_file

      @questions = YAML.load_file(configure_file).
      with_indifferent_access[questions].
      map{ |identifier, properties| Question.new(identifier, properties) }
    end

    def configure
      answers = ask_questions
      save_answers(answers)
    end

    private

    attr_reader :highline, :questions, :answers_file

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

    class Question
      VALID_TYPES = [:boolean, :choice, :integer, :string]

      attr_reader :identifier, :question, :type, :choices

      def initialize(identifier, properties)
        @identifier = identifier
        @question = properties[:question]
        @type = type_for(properties[:type])
        @choices = properties[:choices]
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

      def type_for(value)
        value = value&.to_sym
        if value.nil?
          :string
        elsif valid_type?(value)
          value
        else
          raise UnknownQuestionTypeError
        end
      end

      def valid_type?(value)
        VALID_TYPES.include?(value)
      end
    end

  end
end
