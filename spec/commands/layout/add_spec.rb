# frozen_string_literal: true

require 'shared_examples/record_add_command'

RSpec.describe Metalware::Commands::Layout::Add do
  let(:record_path) do
    Metalware::FilePath.layout(type.pluralize, saved_record_name)
  end

  it_behaves_like 'record add command'
end
