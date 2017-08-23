# frozen_string_literal: true

class Nodes::BuildController < ApplicationController
  def show
    @title = "Build Node #{node_name}"
  end

  def start
    BuildNodeJob.perform_now(node_name)
    redirect_to node_build_path
  end

  private

  # XXX Same method in `Nodes::ConfigureController`.
  def node_name
    params[:node_id]
  end
end
