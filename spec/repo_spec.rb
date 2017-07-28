
# frozen_string_literal: true

require 'repo'
require 'filesystem'

RSpec.describe Metalware::Repo do
  subject do
    Metalware::Repo.new(Metalware::Config.new)
  end

  let :filesystem do
    FileSystem.setup do |fs|
      configure_data = {
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
      }
      fs.dump('/var/lib/metalware/repo/configure.yaml', configure_data)
    end
  end

  describe '#configure_questions' do
    it 'returns de-duplicated configure.yaml questions' do
      filesystem.test do
        expect(subject.configure_questions).to eq(
          foo: { question: 'foo' },
          bar: { question: 'bar' },
          baz: { question: 'baz' }
        )
      end
    end
  end

  describe '#configure_question_identifiers' do
    it 'returns ordered unique identifiers of all configure.yaml questions' do
      filesystem.test do
        expect(subject.configure_question_identifiers).to eq([:bar, :baz, :foo])
      end
    end
  end
end
