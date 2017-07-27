
# frozen_string_literal: true

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
