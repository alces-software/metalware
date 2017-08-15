# frozen_string_literal: true

class Nodes::BuildController < ApplicationController
  def show
    @name = params[:node_id]
  end
end
