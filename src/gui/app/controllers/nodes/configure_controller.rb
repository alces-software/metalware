# frozen_string_literal: true

class Nodes::ConfigureController < ApplicationController
  def show
    @name = params[:node_id]
    @questions = Configure::Questions.for_node
    @answers = {}
  end
end
