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

require 'templating/iterable_recursive_open_struct'

RSpec.describe Metalware::Templating::IterableRecursiveOpenStruct do
  subject {
    Metalware::Templating::IterableRecursiveOpenStruct.new({
      prop: 'value',
      nested: {
        prop: 'nested_value',
      }
    })
  }

  describe 'property setting and access' do
    it 'works as for RecursiveOpenStruct' do
      expect(subject.prop).to eq('value')
      expect(subject.nested.prop).to eq('nested_value')

      subject.new_prop = 'new_value'
      expect(subject.new_prop).to eq('new_value')
    end
  end

  describe '#each' do
    it 'iterates through the entries' do
      keys = []
      values = []

      subject.each do |k,v|
        keys << k
        values << v
      end

      expect(keys).to eq([:prop, :nested])
      expect(values.first).to eq('value')

      # Converts any hash values to same class before iterating.
      expect(values.last).to eq(
        Metalware::Templating::IterableRecursiveOpenStruct.new({prop: 'nested_value'})
      )
    end
  end

  describe '#each=' do
    it 'raises to prevent setting value for each' do
      expect {
        subject.each = 'some_value'
      }.to raise_error Metalware::IterableRecursiveOpenStructPropertyError
    end
  end
end
