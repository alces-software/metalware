# frozen_string_literal: true

class BuildController < ApplicationController
  layout false, only: [:cancel_button, :messages]

  helper_method \
    :build_cancel_button_path,
    :build_messages_path,
    :build_path,
    :shutdown_build_path,
    :start_build_path

  MESSAGES_KEY = Metalware::Output::MESSAGES_KEY
  GRACEFULLY_SHUTDOWN_KEY = Metalware::Commands::Build::GRACEFULLY_SHUTDOWN_KEY
  COMPLETE_KEY = Metalware::Commands::Build::COMPLETE_KEY

  def show
    @build_ongoing = build_thread_running?
    assign_build_command_status_variables
    assign_build_messages
    define_title(build_ongoing: @build_ongoing)
  end

  def cancel_button
    assign_build_command_status_variables
  end

  def messages
    assign_build_messages
  end

  def start
    build_job_class.perform_now(build_job_identifier)
    redirect_to build_path
  end

  def shutdown
    current_build_job&.thread_variable_set(GRACEFULLY_SHUTDOWN_KEY, true)
    flash[:success] = 'Build process shutting down...'
    redirect_to build_path
  end

  def destroy
    if build_command_complete?
      # Command must be complete otherwise we will not have gracefully shutdown
      # the build command and could leave things in an unexpected state.
      current_build_job.kill
      flash[:success] = 'Build process cleaned up.'
    end
    # XXX Handle the `else` case? Could be reached if either build thread not
    # running or build command not complete.

    redirect_to build_path
  end

  private

  def item_type
    # E.g. `node` for `Nodes::BuildController`
    self.class.to_s.split('::').first.singularize.downcase
  end

  def build_path
    send :"#{item_type}_build_path"
  end

  def start_build_path
    send :"start_#{item_type}_build_path"
  end

  def shutdown_build_path
    send :"shutdown_#{item_type}_build_path"
  end

  def build_cancel_button_path
    send :"cancel_button_#{item_type}_build_path"
  end

  def build_messages_path
    send :"messages_#{item_type}_build_path"
  end

  def current_build_job
    build_job_class.find(build_job_identifier)
  end

  # Whether a build thread is currently running; the build command itself may
  # still have completed/been shutdown and now just be sleeping.
  def build_thread_running?
    !!current_build_job
  end

  # Whether the build command is currently being shutdown, but this has not yet
  # completed.
  def build_command_shutting_down?
    !build_command_complete? &&
      current_build_job&.thread_variable_get(GRACEFULLY_SHUTDOWN_KEY)
  end

  # Whether the build command has completed or been gracefully shutdown.
  def build_command_complete?
    current_build_job&.thread_variable_get(COMPLETE_KEY)
  end

  def assign_build_command_status_variables
    @build_cancelling = build_command_shutting_down?
    @build_complete = build_command_complete?
  end

  def assign_build_messages
    @messages = current_build_job&.thread_variable_get(MESSAGES_KEY)&.reverse || []
  end

  def define_title(build_ongoing:)
    raise NotImplementedError
  end

  def build_job_class
    raise NotImplementedError
  end

  def build_job_identifier
    raise NotImplementedError
  end
end
