
require 'iterable_recursive_open_struct'

RSpec.describe Metalware::IterableRecursiveOpenStruct do
  subject {
    Metalware::IterableRecursiveOpenStruct.new({
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
        Metalware::IterableRecursiveOpenStruct.new({prop: 'nested_value'})
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
