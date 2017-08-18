
# frozen_string_literal: true

class Domain::ConfigureController < ConfigureController
  private

  def title
    'Configure Domain'
  end

  def configure_command
    Metalware::Commands::Configure::Domain
  end

  def questions
    Configure::Questions.for_domain
  end
end
