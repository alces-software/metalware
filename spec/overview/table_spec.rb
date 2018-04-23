# frozen_string_literal: true

require 'overview/table'
require 'fixtures/shared_context/overview'

RSpec.describe Metalware::Overview::Table do
  include_context 'overview context'

  let(:namespaces) { alces.groups }

  let(:table) do
    described_class.new(namespaces, fields).render
  end

  def header
    table.lines[1]
  end

  def body
    table.lines[3..-2].join("\n")
  end

  let(:headers) { fields.map { |h| h[:header] } }

  it 'includes the headers in the table' do
    headers.each do |h|
      expect(header).to include(h) unless h.nil?
    end
  end

  it 'includes the static value in the table' do
    expect(body).to include(static)
  end

  it 'renders the values' do
    expect(body).to include(config_value)
  end
end
