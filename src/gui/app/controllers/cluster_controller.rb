
# frozen_string_literal: true

class ClusterController < ApplicationController
  def show
    @groups = Group.all
  end
end
