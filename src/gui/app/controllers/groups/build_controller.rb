# frozen_string_literal: true

class Groups::BuildController < ApplicationController
  def show
    name = params[:group_id]
    @title = "Build Group #{name}"
  end
end
