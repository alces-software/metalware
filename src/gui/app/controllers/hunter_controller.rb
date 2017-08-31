# frozen_string_literal: true

class HunterController < ApplicationController
  def show
    @currently_hunting = HunterJob.hunting?
    @title = @currently_hunting ? 'Hunting!' : 'Hunt for nodes'

    new_detected_macs_key = Metalware::Commands::Hunter::NEW_DETECTED_MACS_KEY
    @new_detected_macs = \
      HunterJob.current_thread&.thread_variable_get(new_detected_macs_key)
  end

  def start
    HunterJob.perform_now
    redirect_to hunter_path
  end

  def destroy
    HunterJob.current_thread&.kill
    redirect_to hunter_path
  end
end
