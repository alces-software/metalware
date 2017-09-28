# frozen_string_literal: true

class Groups::ConfigureController < ConfigureController
  def start
    name = params[:group_name]
    redirect_to group_configure_path(name)
  end

  private

  def configure_item
    "Group #{group_name}"
  end

  def configure_command
    Metalware::Commands::Configure::Group
  end

  def configure_command_args
    [group_name]
  end

  def questions
    Configure::Questions.for_group(group_name)
  end
end
