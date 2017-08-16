# frozen_string_literal: true

class Groups::ConfigureController < ApplicationController
  def start
    name = params[:group_name]
    redirect_to (group_configure_path name)
  end

  def show
    @name = params[:group_id]
    @questions = Configure::Questions.for_group
    @answers = {}
  end
end
