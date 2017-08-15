class Groups::BuildController < ApplicationController
  def show
    @name = params[:group_id]
  end
end
