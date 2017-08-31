# frozen_string_literal: true

class Groups::BuildController < BuildController
  private

  alias build_path group_build_path

  def define_title(build_ongoing:)
    title_prefix = build_ongoing ? 'Building' : 'Build'
    @title = "#{title_prefix} Group #{group_name}"
  end

  def build_job_class
    BuildGroupJob
  end

  # XXX Same method in `Groups::ConfigureController`.
  def group_name
    params[:group_id]
  end
  alias build_job_identifier group_name
end
