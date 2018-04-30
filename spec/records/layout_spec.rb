# frozen_string_literal: true

require 'spec_utils'
require 'shared_examples/record'
require 'records/layout'

RSpec.describe Metalware::Records::Layout do
  include AlcesUtils
  before { allow(Metalware::Utils::Editor).to receive(:open) }

  file_path_proc = proc do |types_dir, name|
    Metalware::FilePath.layout(types_dir, name)
  end

  let(:valid_path) { Metalware::FilePath.layout('rack', 'saved-layout') }
  let(:invalid_path) { Metalware::FilePath.asset('server', 'saved-asset') }

  it_behaves_like 'record', file_path_proc
end
