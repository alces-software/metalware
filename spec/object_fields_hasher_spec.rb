
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

require 'object_fields_hasher'

RSpec.describe Metalware::ObjectFieldsHasher do
  class MyClass
    attr_reader :foo, :bar

    def initialize(foo, bar)
      @foo = foo
      @bar = bar
    end

    private

    def customize_foo
      foo + '_customized'
    end
  end

  describe '#hash_object' do
    subject { MyClass.new('my_foo', 'my_bar') }

    it "converts the object's unique instance methods to hash properties" do
      expect(
        Metalware::ObjectFieldsHasher.hash_object(subject)
      ).to eq(foo: 'my_foo', bar: 'my_bar')
    end

    it 'uses given method instead for passed in method keys' do
      expect(
        Metalware::ObjectFieldsHasher.hash_object(subject, foo: :customize_foo)
      ).to eq(foo: 'my_foo_customized', bar: 'my_bar')
    end
  end
end
