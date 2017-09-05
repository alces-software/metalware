# frozen_string_literal: true

class Nodes::ConfigureController < ConfigureController
  private

  def configure_item
    "Node #{node_name}"
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
end
