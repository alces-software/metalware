# frozen_string_literal: true

class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  def self.credentials
    @credentials ||=
      OpenStruct.new(
        Metalware::Data.load(
          Metalware::Constants::GUI_CREDENTIALS_PATH
        )
      )
  end
  http_basic_authenticate_with name: credentials.username,
                               password: credentials.password

  def run_command(command_class, *args, **options_hash)
    Metalware::Utils.run_command(command_class, *args, **options_hash)
    true
  rescue Metalware::MetalwareError => error
    flash.now[:error] = error.message
    false
  end

  # Get the name of the associated node for a nested node controller
  # (`Nodes::BuildController`, `Nodes::ConfigureController` etc.).
  def node_name
    params[:node_id]
  end

  # Similarly to `node_name` for nested group controllers.
  def group_name
    params[:group_id]
  end
end
