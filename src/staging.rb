# frozen_string_literal: true

require 'data'
require 'file_path'
require 'recursive-open-struct'
require 'templater'
require 'managed_file'

module Metalware
  class Staging
    def self.update(metal_config)
      staging = new(metal_config)
      yield staging if block_given?
    ensure
      staging.save
    end

    def self.template(metal_config)
      update(metal_config) do |staging|
        yield Templater.new(staging) if block_given?
      end
    end

    def self.manifest(metal_config)
      new(metal_config).manifest
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
      validate(data, content)
      FileUtils.mkdir_p(File.dirname(data[:sync])) if data[:mkdir]
      File.write(data[:sync], content)
      FileUtils.rm(data[:staging])
    end

    def validate(data, content)
      return unless data[:validator]
      unless data[:validator].new.validate(content)
        msg = "A file failed the following validator: #{data[:validator]}\n"
        msg += "File: #{data[:staging]}"
        msg += "Managed?: #{data[:managed]}"
        raise ValidationFailure, msg
      end
    end
  end
end
