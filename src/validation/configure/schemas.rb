# frozen_string_literal: true

module Metalware
  module Validation
    class Configure
      TopLevelSchema = Dry::Validation.Schema do
        configure do
          config.messages_file = FilePath.dry_validation_errors
          config.namespace = :configure

          def top_level_keys?(data)
            section = Constants::CONFIGURE_SECTIONS.dup.push(:questions)
            (data.keys - section).empty?
          end
        end

        required(:data) { top_level_keys? }
      end

      DependantSchema = Dry::Validation.Schema do
        configure do
          config.messages_file = FilePath.dry_validation_errors
          config.namespace = :configure
        end

        optional(:dependent) { array? && (each { hash? }) }
      end

      QuestionFieldSchema = Dry::Validation.Schema do
        configure do
          config.messages_file = FilePath.dry_validation_errors
          config.namespace = :configure

          def supported_type?(value)
            SUPPORTED_TYPES.include?(value)
          end

          def default?(value)
            return true if value.is_a?(String)
            value.respond_to?(:empty?) ? value.empty? : true
          end
        end

        required(:identifier) { filled? & str? }
        required(:question) { filled? & str? }
        optional(:optional) { bool? }
        optional(:type) { supported_type? }
        optional(:default) { default? }
        optional(:choice) { array? }
      end

      QuestionSchema = Dry::Validation.Schema do
        configure do
          config.messages_file = FilePath.dry_validation_errors
          config.namespace = :configure

          def default_type?(value)
            default = value[:default]
            type = value[:type]
            return true if default.nil?
            ::Metalware::Validation::Configure.type_check(type, default)
          end

          def choice_with_default?(value)
            return true if value[:choice].nil? || value[:default].nil?
            return false unless value[:choice].is_a?(Array)
            value[:choice].include?(value[:default])
          end

          def choice_type?(value)
            return true if value[:choice].nil?
            return false unless value[:choice].is_a?(Array)
            value[:choice].each do |choice|
              type = value[:type]
              r = ::Metalware::Validation::Configure.type_check(type, choice)
              return false unless r
            end
            true
          end
        end

        required(:question) do
          default_type? & \
            choice_with_default? & \
            choice_type? & \
            schema(DependantSchema) & \
            schema(QuestionFieldSchema)
        end
      end
    end
  end
end
