# frozen_string_literal: true

class HunterController < ApplicationController
  def show
    # XXX This conditional only exists to allow easier development of hunter
    # page, by using fake hunter data when the `fake_hunting` parameter is set
    # in development - remove/improve this?
    if fake_hunting?
      @currently_hunting = true
      @new_detected_macs = ['fake-mac-1', 'fake-mac-2']
    else
      @currently_hunting = HunterJob.hunting?
      new_detected_macs_key = Metalware::Commands::Hunter::NEW_DETECTED_MACS_KEY
      @new_detected_macs = \
        HunterJob.current_thread&.thread_variable_get(new_detected_macs_key) || []
    end

    @title = @currently_hunting ? 'Hunting!' : 'Hunt for nodes'
  end

  def start
    HunterJob.perform_now
    redirect_to hunter_path
  end

  def destroy
    HunterJob.current_thread&.kill
    redirect_to hunter_path
  end

  def record_node
    # XXX This bypasses the logging done when we record pairs in the `Hunter`
    # command - possibly we should share code between these somehow?
    hunter_updater.add(params[:node_name], params[:mac_address])
    # XXX Show flash message here
    redirect_to hunter_path
  end

  private

  def fake_hunting?
    Rails.env.development? && params[:fake_hunting]
  end

  def hunter_updater
    @hunter_updater ||=
      Metalware::HunterUpdater.new(Metalware::Constants::HUNTER_PATH)
  end
end
