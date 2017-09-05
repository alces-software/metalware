# frozen_string_literal: true

class HunterController < ApplicationController
  layout false, only: :new_detected_node_rows

  def show
    @currently_hunting = fake_hunting? ? true : HunterJob.hunting?
    @title = @currently_hunting ? 'Hunting!' : 'Hunt for nodes'
    assign_mac_address_variables
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
    node_name = params[:node_name]
    mac_address = params[:mac_address]
    hunter_updater.add(node_name, mac_address)
    flash[:success] = \
      "MAC address <code>#{mac_address}</code> associated with node <strong>#{node_name}</strong>."
    redirect_to hunter_path
  end

  def new_detected_node_rows
    assign_mac_address_variables
    @known_macs = params[:known_mac_addresses] || []
  end

  private

  def default_url_options(options = {})
    # Have `fake_hunting` param persist across multiple requests, if set (see
    # https://stackoverflow.com/a/12819053).
    if fake_hunting?
      options.merge(fake_hunting: params[:fake_hunting])
    else
      options
    end
  end

  # XXX This method only exists to allow easier development of hunter page, by
  # using fake hunter data when the `fake_hunting` parameter is set in
  # development - remove/improve usage of this?
  def fake_hunting?
    Rails.env.development? && params[:fake_hunting]
  end

  def assign_mac_address_variables
    if fake_hunting?
      @new_detected_macs = ['fake-mac-1', 'fake-mac-2']
    else
      new_detected_macs_key = Metalware::Commands::Hunter::NEW_DETECTED_MACS_KEY
      @new_detected_macs = \
        HunterJob.current_thread&.thread_variable_get(new_detected_macs_key) || []
    end

    @hunter_macs_to_nodes = Metalware::Data.load(Metalware::Constants::HUNTER_PATH).invert
  end

  def hunter_updater
    @hunter_updater ||=
      Metalware::HunterUpdater.new(Metalware::Constants::HUNTER_PATH)
  end
end
