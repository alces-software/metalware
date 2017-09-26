# frozen_string_literal: true

class Nodes::BuildController < BuildController
  private

  alias build_job_identifier node_name

  def define_title(build_ongoing:)
    title_prefix = build_ongoing ? 'Building' : 'Build'
    @title = "#{title_prefix} Node #{node_name}"
  end

  def build_job_class
    BuildNodeJob
  end
end
