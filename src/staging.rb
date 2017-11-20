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
      @manifest = RecursiveOpenStruct.new(manifest_hash)
    end

    attr_reader :manifest

    def save
      Data.dump(file_path.staging_manifest, manifest.to_h)
    end

    def push_file(sync, content, managed: false, validator: nil)
      staging = file_path.staging(sync)
      FileUtils.mkdir_p(File.dirname(staging))
      File.write(staging, content)

      manifest.files.push(RecursiveOpenStruct.new(
                            sync: sync,
                            staging: staging,
                            managed: managed,
                            validator: validator
      ))
    end

    private

    attr_reader :metal_config, :file_path

    def blank_manifest
      { files: [] }
    end
  end
end
