# frozen_string_literal: true

require 'data'
require 'file_path'
require 'recursive-open-struct'
require 'templater'
require 'managed_file'
require 'config'

module Metalware
  class Staging
    def self.update(_remove_this_input = nil)
      staging = new
      yield staging if block_given?
    ensure
      staging.save
    end

    def self.template(_remove_this_input = nil)
      update do |staging|
        yield Templater.new(staging) if block_given?
      end
    end

    def self.manifest(_remove_this_input = nil)
      new.manifest
    end

    private_class_method :new

    def initialize
      @metal_config = Config.cache
      @file_path = FilePath.new(metal_config)
    end

    def save
      Data.dump(file_path.staging_manifest, manifest.to_h)
    end

    def manifest
      @manifest ||= begin
        Data.load(file_path.staging_manifest).tap do |x|
          x.merge! blank_manifest if x.empty?
          # Converts the file paths to strings
          x[:files] = x[:files].map { |key, data| [key.to_s, data] }.to_h
        end
      end
    end

    def push_file(sync, content, **options)
      staging = file_path.staging(sync)
      FileUtils.mkdir_p(File.dirname(staging))
      File.write(staging, content)
      manifest[:files][sync] = default_push_options.merge(options)
    end

    def delete_file_if
      manifest[:files].delete_if do |sync_path, raw_data|
        ret = nil
        begin
          data = OpenStruct.new(raw_data.merge(
            sync: sync_path,
            staging: FilePath.staging(sync_path)
          ))
          data.content = file_content(data)
          ret = yield OpenStruct.new(data)
        rescue => e
          MetalLog.warn e.inspect
          ret = false
        end
        FileUtils.rm FilePath.staging(sync_path) if ret
        ret
      end
    end

    def sync_files
      delete_file_if do |file|
        validate(file)
        FileUtils.mkdir_p File.dirname(file.sync)
        File.write(file.sync, file.content)
      end
    end

    def restart_service
      manifest[:restart_service]
    end

    private

    attr_reader :metal_config, :file_path

    def default_push_options
      {
        managed: false,
        validator: nil,
        mkdir: false,
      }
    end

    def blank_manifest
      { files: {}, restart_service: [] }
    end

    def file_content(data)
      raw = File.read data.staging
      data.managed ? ManagedFile.content(data.sync, raw) : raw
    end

    def move_file(data, content)
      FileUtils.mkdir_p(File.dirname(data[:sync])) if data[:mkdir]
      File.write(data[:sync], content)
      FileUtils.rm(data[:staging])
    end

    def validate(data)
      return unless data.validator
      error = nil
      begin
        return if data.validator.constantize.validate(data.content)
      rescue => e
        error = e
      end
      msg = 'A file failed to be validated'
      msg += "\nFile: #{data.staging}"
      msg += "\nValidator: #{data.validator}"
      msg += "\nManaged: #{data.managed}"
      msg += "\nError: #{error.inspect}" if error
      raise ValidationFailure, msg
    end
  end
end
