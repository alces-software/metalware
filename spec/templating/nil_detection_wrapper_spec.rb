
# frozen_string_literal: true

require 'templating/nil_detection_wrapper'
require 'recursive_open_struct'
require 'metal_log'
require 'alces_utils'

RSpec.describe Metalware::Templating::NilDetectionWrapper do
  AlcesUtils.start self

  def build_wrapper_object(obj)
    Metalware::Templating::NilDetectionWrapper.wrap(obj).receiver
  end

  let :metal_log { Metalware::MetalLog.metal_log }

  it 'the wrap command returns a binding' do
    expect(Metalware::Templating::NilDetectionWrapper.wrap(nil)).to \
      be_a(Binding)
  end

  context 'with a wrapped integer' do
    let :object { 100 }
    let :wrapped_object { build_wrapper_object(object) }

    it 'the wrapped object is equal to the object' do
      expect(wrapped_object).to eq(object)
    end

    context 'when multipled by 0' do
      let :zero_object { wrapped_object * 0 }

      it 'equals the correct value' do
        expect(zero_object).to eq(0)
      end

      it 'can have methods called on it' do
        expect(zero_object.zero?).to eq(true)
      end
    end
  end

  context 'with a recursive_open_struct object' do
    let :object do
      RecursiveOpenStruct.new(
        nil: nil,
        key1: {
          key2: {
            key3: {
              key4: nil,
            },
          },
        },
      )
    end

    let :wrapped_object { build_wrapper_object(object) }

    it 'issues for a simple nil return value' do
      expect(metal_log).to receive(:warn).once
      wrapped_object.nil
    end

    it 'issues a warning for a nested nil' do
      expect(metal_log).to receive(:warn).once
      wrapped_object.key1.key2.key3.key4
    end
  end
end
