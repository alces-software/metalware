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
      staging = new(Config.cache)
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
      new(Config.cache).manifest
    end

    private_class_method :new

    def initialize(metal_config)
      @metal_config = metal_config
      @file_path = FilePath.new(metal_config)
      manifest_hash = Data.load(file_path.staging_manifest)
      manifest_hash = blank_manifest if manifest_hash.empty?
      @manifest = RecursiveOpenStruct.new(
        manifest_hash, recurse_over_arrays: true
      )
    end

    attr_reader :manifest

    def save
      Data.dump(file_path.staging_manifest, manifest.to_h)
    end

    def push_file(sync, content, **options)
      staging = file_path.staging(sync)
      FileUtils.mkdir_p(File.dirname(staging))
      File.write(staging, content)

      manifest.files.push(
        {
          sync: sync,
          staging: staging,
        }.merge(default_push_options)
         .merge(options)
      )
    end

    def sync_files
      manifest.files.delete_if do |data|
        return_value = nil
        begin
          managed = data[:managed]
          content = File.read(data[:staging])
          content = ManagedFile.content(data[:sync], content) if managed
          validate(data, content)
          move_file(data, content)
          return_value = true
        rescue => e
          $stderr.puts e.inspect
          return_value = false
        end
        return_value
      end
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
      { files: [] }
    end

    def move_file(data, content)
      FileUtils.mkdir_p(File.dirname(data[:sync])) if data[:mkdir]
      File.write(data[:sync], content)
      FileUtils.rm(data[:staging])
    end

    def validate(data, content)
      return unless data[:validator]
      error = nil
      begin
        return if data[:validator].constantize.validate(content)
      rescue => e
        error = e
      end
      msg = "A file failed to be validated"
      msg += "\nFile: #{data[:staging]}"
      msg += "\nValidator: #{data[:validator]}"
      msg += "\nManaged: #{data[:managed]}"
      msg += "\nError: #{error.inspect}" if error
      raise ValidationFailure, msg
    end
  end
end
