# frozen_string_literal: true

class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  def run_command(command_class, *args, **options_hash)
    Metalware::Utils.run_command(command_class, *args, **options_hash)
    true
  rescue Metalware::MetalwareError => error
    flash.now[:error] = error.message
    false
  end
end
