# frozen_string_literal: true

class BuildController < ApplicationController
  def show
    build_job = build_job_class.find(build_job_identifier)
    @build_ongoing = !!build_job
    @messages = build_job&.thread_variable_get(:messages) || []
    define_title(build_ongoing: @build_ongoing)
  end

  def start
    build_job_class.perform_now(build_job_identifier)
    redirect_to build_path
  end

  def destroy
    build_job = build_job_class.find(build_job_identifier)
    build_job&.kill
    redirect_to build_path
  end

  private

  def define_title(build_ongoing:)
    raise NotImplementedError
  end

  def build_job_class
    raise NotImplementedError
  end

  def build_path
    raise NotImplementedError
  end

  def build_job_identifier
    raise NotImplementedError
  end
end
