# frozen_string_literal: true

module Metalware
  module Overview
    class Table
      attr_reader :fields
      attr_reader :namespaces

      def initialize(namespaces, fields)
        @fields = fields
        @namespaces = namespaces
      end

      def render
        Terminal::Table.new(headings: headers, rows: rows).render
      end

      private

      def headers
        fields.map { |f| f[:header] }
      end

      def unrendered_values
        fields.map { |f| f[:value] || '' }
      end

      def rows
        namespaces.map { |namespace| row(namespace) }
      end

      def row(namespace)
        unrendered_values.map do |value|
          namespace.render_erb_template(value)
        end
      end
    end
  end
end
