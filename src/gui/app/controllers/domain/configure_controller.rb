# frozen_string_literal: true

class Domain::ConfigureController < ApplicationController
  def show
    @questions = Configure::Questions.for_domain
  end
end
