
require 'active_support/core_ext/hash'


module Metalware
  class Configurator
    def initialize(highline:, configure_file:, questions:, answers_file:)
      @highline = highline
      @answers_file = answers_file
      @questions = YAML.load_file(
        configure_file
      ).with_indifferent_access[questions]
    end

    def configure
      answers = ask_questions
      save_answers(answers)
    end

    private

    def ask_questions
      questions.map do |identifier, properties|
        question = Question.new(identifier, properties)
        answer = question.ask(highline)
        [identifier, answer]
      end.to_h
    end

    def save_answers(answers)
      File.open(answers_file, 'w') do |f|
        f.write(YAML.dump(answers))
      end
    end

    class Question
      attr_reader :identifier, :question, :type, :choices

      def initialize(identifier, properties)
        @identifier = identifier
        @question = properties[:question]
        @type = properties[:type]
        @choices = properties[:choices]
      end

      def ask(highline)
        case type
        when 'boolean'
          highline.agree(question)
        when 'choice'
          highline.choose(*choices) do |menu|
            menu.prompt = question
          end
        when 'integer'
          highline.ask(question, Integer)
        else
          highline.ask(question)
        end
      end
    end

    attr_reader :highline, :questions, :answers_file
  end
end
