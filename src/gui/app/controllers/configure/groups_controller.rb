class Configure::GroupsController < ApplicationController
  def show
    @name = params[:id]
    @questions = Configure::Questions.for_group
  end

  def create
    name = params[:group_name]
    redirect_to (configure_group_path name)
  end
end
