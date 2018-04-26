# frozen_string_literal: true

require 'spec_utils'
require 'shared_examples/record'
require 'records/layout'

RSpec.describe Metalware::Records::Layout do
  file_path_proc = proc do |types_dir, name|
    Metalware::FilePath.layout(types_dir, name)
  end

  it_behaves_like 'record', file_path_proc
end
