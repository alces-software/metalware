# frozen_string_literal: true

class Configure::DomainController < ApplicationController
  def show
    @questions = Configure::Questions.for_domain
  end
end
