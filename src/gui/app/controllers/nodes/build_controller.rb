# frozen_string_literal: true

class Nodes::BuildController < ApplicationController
  def show
    build_job = BuildNodeJob.find(node_name)

    @build_ongoing = !!build_job

    title_prefix = @build_ongoing ? 'Building' : 'Build'
    @title = "#{title_prefix} Node #{node_name}"
  end

  def start
    BuildNodeJob.perform_now(node_name)
    redirect_to node_build_path
  end

  def destroy
    build_job = BuildNodeJob.find(node_name)
    build_job.kill if build_job
    redirect_to node_build_path
  end

  private

  # XXX Same method in `Nodes::ConfigureController`.
  def node_name
    params[:node_id]
  end
end
