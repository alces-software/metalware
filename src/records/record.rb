# frozen_string_literal: true

require 'file_path'
require 'namespaces/asset_array'

module Metalware
  module Records
    class Record
      TYPES = begin
        Dir.glob(Metalware::FilePath.asset_type('*')).map do |path|
          File.basename(path, '.yaml')
        end
      end.freeze

      class << self
        def path(name, missing_error: false)
          paths.find { |path| name == File.basename(path, '.yaml') }
               .tap do |path|
            raise_missing_record(name) if missing_error && !path
          end
        end

        def paths
          raise NotImplementedError
        end

        def available?(name)
          if TYPES.include?(name) || TYPES.map(&:pluralize).include?(name)
            false
          elsif reserved_methods.include?(name)
            false
          elsif name.include?('/')
            false
          else
            !path(name)
          end
        end

        def error_if_unavailable(name)
          return if available?(name)
          msg = if path(name)
                  <<-EOF.squish
                    The "#{name}" #{class_name} already exists. Please use
                    `metal #{class_name} edit` instead
                  EOF
                else
                  "\"#{name}\" is not a valid #{class_name} name"
                end
          raise InvalidInput, msg
        end

        def type_from_path(path)
          return (path.gsub(record_dir, '').split('/')[1]).singularize if
            path.include? record_dir
          raise InvalidInput, <<-EOF.squish
            Expected path to start with #{record_dir} for #{class_name} type
          EOF
        end

        private

        def record_dir
          raise NotImplementedError
        end

        def class_name
          to_s.gsub(/^.*::/, '').downcase
        end

        def raise_missing_record(name)
          raise MissingRecordError, <<-EOF.squish
            The "#{name}" #{class_name} does not exist
          EOF
        end

        def reserved_methods
          @reserved_methods ||= begin
            Namespaces::AssetArray.instance_methods.concat(
              Namespaces::AssetArray.private_instance_methods
            ).uniq.map(&:to_s)
          end
        end
      end
    end
  end
end
