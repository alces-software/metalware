# frozen_string_literal: true

class BuildGroupJob < BuildJob
  IDENTIFIER = :group_name

  def run_build_command(group_name)
    Metalware::Utils.run_command(
      Metalware::Commands::Build,
      group_name,
      group: true
    )
  end
end
