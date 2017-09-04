# frozen_string_literal: true

class BuildController < ApplicationController
  MESSAGES_KEY = Metalware::Output::MESSAGES_KEY
  GRACEFULLY_SHUTDOWN_KEY = Metalware::Commands::Build::GRACEFULLY_SHUTDOWN_KEY

  def show
    @build_ongoing = !!current_build_job
    @messages = current_build_job&.thread_variable_get(MESSAGES_KEY)&.reverse || []
    define_title(build_ongoing: @build_ongoing)
  end

  def start
    build_job_class.perform_now(build_job_identifier)
    redirect_to build_path
  end

  def destroy
    current_build_job&.thread_variable_set(GRACEFULLY_SHUTDOWN_KEY, true)
    redirect_to build_path
  end

  private

  def current_build_job
    build_job_class.find(build_job_identifier)
  end

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
