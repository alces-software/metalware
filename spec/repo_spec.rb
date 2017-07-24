
# frozen_string_literal: true

require 'repo'

RSpec.describe Metalware::Repo do
  subject do
    Metalware::Repo.new(Metalware::Config.new)
  end

  describe '#configure_questions' do
    it 'returns ordered unique identifiers of all configure.yaml questions' do
      FileSystem.test do
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
        Metalware::Data.dump('/var/lib/metalware/repo/configure.yaml', configure_data)

        expect(subject.configure_questions).to eq([:bar, :baz, :foo])
      end
    end
  end
end
