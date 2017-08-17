# frozen_string_literal: true

class Domain::ConfigureController < ApplicationController
  def show
    assign_form_variables
  end

  def create
    answers = params[:answers].permit!.to_h
    if configure_with_answers(answers)
      redirect_to '/'
    else
      assign_form_variables(entered_answers: answers)
      render 'show'
    end
  end

  private

  def assign_form_variables(entered_answers: {})
    @title = 'Configure Domain'
    @questions = Configure::Questions.for_domain
    @answers = entered_answers
  end

  def configure_with_answers(answers)
    run_command(
      Metalware::Commands::Configure::Domain,
      answers: answers.to_json
    )
  end
end
