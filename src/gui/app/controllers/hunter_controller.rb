# frozen_string_literal: true

class HunterController < ApplicationController
  def show
    @currently_hunting = HunterJob.hunting?
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
end
