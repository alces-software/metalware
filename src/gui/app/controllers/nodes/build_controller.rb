# frozen_string_literal: true

class Nodes::BuildController < ApplicationController
  def show
    name = params[:node_id]
    @title = "Build Node #{name}"
  end
end
