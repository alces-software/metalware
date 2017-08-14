class Configure::NodesController < ApplicationController
  def show
    @name = params[:id]
    @questions = Configure::Questions.for_node
  end
end
