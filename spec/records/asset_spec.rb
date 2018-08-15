# frozen_string_literal: true

require 'spec_utils'
require 'shared_examples/record'

RSpec.describe Metalware::Records::Asset do
  file_path_proc = proc do |types_dir, name|
    Metalware::FilePath.asset(types_dir, name)
  end

  let(:valid_path) { Metalware::FilePath.asset('rack', 'saved-asset') }
  let(:invalid_path) { Metalware::FilePath.layout('server', 'saved-layout') }

  it_behaves_like 'record', file_path_proc
end
