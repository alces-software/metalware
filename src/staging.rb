# frozen_string_literal: true

require 'data'
require 'file_path'
require 'recursive-open-struct'
require 'templater'

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

    def push_file(sync, content, managed: false, validator: nil)
      staging = file_path.staging(sync)
      FileUtils.mkdir_p(File.dirname(staging))
      File.write(staging, content)

      manifest.files.push(
        sync: sync,
        staging: staging,
        managed: managed,
        validator: validator
      )
    end

    def sync_files
      manifest.files.delete_if do |data|
        begin
          data[:managed] ? move_managed(data) : move_non_managed(data)
          true
        rescue => e
          $stderr.puts e.inspect
          return false
        end
      end
    end

    private

    attr_reader :metal_config, :file_path

    def blank_manifest
      { files: [] }
    end

    def move_managed(data)
      raise NotImplementedError
    end

    def move_non_managed(data)
      validate(data, File.read(data[:staging]))
      FileUtils.mv data[:staging], data[:sync]
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
