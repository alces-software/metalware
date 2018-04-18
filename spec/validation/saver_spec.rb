# frozen_string_literal: true

#==============================================================================
# Copyright (C) 2017 Stephen F. Norledge and Alces Software Ltd.
#
# This file/package is part of Alces Metalware.
#
# Alces Metalware is free software: you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License
# as published by the Free Software Foundation, either version 3 of
# the License, or (at your option) any later version.
#
# Alces Metalware is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this package.  If not, see <http://www.gnu.org/licenses/>.
#
# For more information on the Alces Metalware, please visit:
# https://github.com/alces-software/metalware
#==============================================================================

require 'validation/saver'
require 'validation/answer'
require 'filesystem'
require 'file_path'
require 'data'
require 'alces_utils'

module SaverSpec
  module TestingMethods
    def input_test(*a)
      a
    end

    def data_test(*_a)
      data
    end
  end
end
Metalware::Validation::Saver::Methods.prepend(SaverSpec::TestingMethods)

RSpec.describe Metalware::Validation::Saver do
  include AlcesUtils

  let(:path) { Metalware::FilePath }
  let(:saver) { described_class.new }
  let(:stubbed_answer_load) { OpenStruct.new(data: data) }
  let(:data) { { key: 'data' } }

  let(:filesystem) do
    FileSystem.setup(&:with_minimal_repo)
  end

  it 'errors if method is not defined' do
    expect do
      saver.not_found_methods('data')
    end.to raise_error(NoMethodError)
  end

  it 'errors if data is not included' do
    expect do
      saver.domain_answers
    end.to raise_error(Metalware::SaverNoData)
  end

  it 'passes an arguments and data to the save method' do
    inputs = ['arg1', hash: 'value']
    expect(
      saver.input_test(data, *inputs)
    ).to eq(inputs)
    expect(
      saver.data_test(data, *inputs)
    ).to eq(data)
  end

  it 'calls the answer validator with the domain and data' do
    filesystem.test do
      expect(Metalware::Validation::Answer).to \
        receive(:new).with(data, answer_section: :domain)
                     .and_return(stubbed_answer_load)
      saver.domain_answers(data)
      expect(Metalware::Data.load(path.domain_answers)).to eq(data)
    end
  end
end
