# frozen_string_literal: true

class Nodes::ConfigureController < ConfigureController
  private

  def title
    "Configure Node #{node_name}"
  end

  def configure_command
    Metalware::Commands::Configure::Node
  end

  def configure_command_args
    [node_name]
  end

  def questions
    Configure::Questions.for_node(node_name)
  end

  def node_name
    params[:node_id]
  end
end
