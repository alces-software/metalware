# frozen_string_literal: true

class BuildController < ApplicationController
  MESSAGES_KEY = Metalware::Output::MESSAGES_KEY
  GRACEFULLY_SHUTDOWN_KEY = Metalware::Commands::Build::GRACEFULLY_SHUTDOWN_KEY
  COMPLETE_KEY = Metalware::Commands::Build::COMPLETE_KEY

  def show
    @build_ongoing = !!current_build_job
    @build_complete = build_command_complete?

    @messages = current_build_job&.thread_variable_get(MESSAGES_KEY)&.reverse || []
    define_title(build_ongoing: @build_ongoing)
  end

  def start
    build_job_class.perform_now(build_job_identifier)
    redirect_to build_path
  end

  def shutdown
    current_build_job&.thread_variable_set(GRACEFULLY_SHUTDOWN_KEY, true)
    redirect_to build_path
  end

  def destroy
    if build_command_complete?
      # Command must be complete otherwise we will not have gracefully shutdown
      # the build command and could leave things in an unexpected state.
      current_build_job.kill
    end
    # XXX Handle the `else` case? Could be reached if either build thread not
    # running or build command not complete.

    redirect_to build_path
  end

  private

  def current_build_job
    build_job_class.find(build_job_identifier)
  end

  def build_command_complete?
    # Whether the build command has completed or been gracefully shutdown.
    current_build_job&.thread_variable_get(COMPLETE_KEY)
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
