
# frozen_string_literal: true

class ClusterController < ApplicationController
  def show
    redirect_to root_path unless request.fullpath == root_path
    @title = 'Cluster Overview'
    @groups = Group.all
  end
end
