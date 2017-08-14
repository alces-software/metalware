class Configure::GroupsController < ApplicationController
  def show
    @name = params[:id]
    @questions = Configure::Questions.for_group
  end
end
