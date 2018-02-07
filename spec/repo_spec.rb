
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

require 'repo'
require 'validation/loader'
require 'config'

RSpec.describe Metalware::Repo do
  subject { Metalware::Repo.new }

  let :configure_data do
    {
      domain: {
        foo: { question: 'foo' },
        bar: { question: 'bar' },
      },
      group: {
        bar: { question: 'bar' },
      },
      node: {
        baz: { question: 'baz' },
      },
      local: {},
    }
  end
  let :loader { Metalware::Validation::Loader.new }

  # Spoofs the Loader to return the configure_data above. By-passes validation
  before :each do
    allow(loader).to receive(:configure_data).and_return(configure_data)
    allow(Metalware::Validation::Loader).to receive(:new).and_return(loader)
  end

  describe '#configure_questions' do
    it 'returns de-duplicated configure.yaml questions' do
      expect(subject.configure_questions).to eq(
        foo: { question: 'foo' },
        bar: { question: 'bar' },
        baz: { question: 'baz' }
      )
    end
  end

  describe '#configure_question_identifiers' do
    it 'returns ordered unique identifiers of all configure.yaml questions' do
      expect(subject.configure_question_identifiers).to eq([:bar, :baz, :foo])
    end
  end
end
