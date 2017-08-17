# frozen_string_literal: true

class Nodes::ConfigureController < ApplicationController
  def show
    name = params[:node_id]
    @title = "Configure Node #{name}"
    @questions = Configure::Questions.for_node
    @answers = {}
  end
end
