# frozen_string_literal: true

class BuildNodeJob < BuildJob
  IDENTIFIER = :node_name

  def run_build_command(node_name)
    Metalware::Utils.run_command(Metalware::Commands::Build, node_name)
  end
end
