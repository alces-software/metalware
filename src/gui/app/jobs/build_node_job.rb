# frozen_string_literal: true

class BuildNodeJob < ApplicationJob
  queue_as :default

  def perform(node_name)
    Thread.new do
      Metalware::Utils.run_command(Metalware::Commands::Build, node_name)
    end
  end
end
