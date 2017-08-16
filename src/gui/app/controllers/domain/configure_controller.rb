# frozen_string_literal: true

class Domain::ConfigureController < ApplicationController
  def show
    load_questions
  end

  def create
    answers = params[:answers]
    if configure_with_answers(answers)
      redirect_to '/'
    else
      load_questions
      render 'show'
    end
  end

  private

  def load_questions
    @questions = Configure::Questions.for_domain
  end

  def configure_with_answers(answers)
    run_command(
      Metalware::Commands::Configure::Domain,
      answers: answers.to_json
    )
  end
end
