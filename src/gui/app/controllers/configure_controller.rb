
# frozen_string_literal: true

class ConfigureController < ApplicationController
  def show
    assign_form_variables
  end

  def create
    if configure_with_answers(entered_answers)
      redirect_to '/'
    else
      assign_form_variables
      render 'show'
    end
  end

  private

  def assign_form_variables
    @title = title
    @questions = questions

    # If we've been sent some `answers` in the request then these will be
    # re-shown in the form, otherwise we will show the old saved answers.
    entered_answers if params[:answers]
  end

  def entered_answers
    @entered_answers ||=
      params[:answers].permit!.to_h.select do |_identifier, answer|
        answer.present?
      end
  end

  def configure_with_answers(answers)
    run_command(
      configure_command,
      answers: answers.to_json
    )
  end

  def title
    raise NotImplementedError
  end

  def configure_command
    raise NotImplementedError
  end

  def questions
    raise NotImplementedError
  end
end
