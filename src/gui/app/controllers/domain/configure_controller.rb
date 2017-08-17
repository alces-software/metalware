# frozen_string_literal: true

class Domain::ConfigureController < ApplicationController
  def show
    assign_form_variables
  end

  def create
    if configure_with_answers(entered_answers)
      redirect_to '/'
    else
      assign_form_variables(entered_answers: entered_answers)
      render 'show'
    end
  end

  private

  def assign_form_variables(entered_answers: {})
    @title = 'Configure Domain'
    @questions = Configure::Questions.for_domain
    @answers = entered_answers
  end

  def entered_answers
    @entered_answers ||=
      params[:answers].permit!.to_h.select do |_identifier, answer|
        answer.present?
      end
  end

  def configure_with_answers(answers)
    run_command(
      Metalware::Commands::Configure::Domain,
      answers: answers.to_json
    )
  end
end
