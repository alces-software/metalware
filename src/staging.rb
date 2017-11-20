# frozen_string_literal: true

require 'data'
require 'file_path'

module Metalware
  class Staging
    def initialize(metal_config)
      @metal_config = metal_config
      @file_path = FilePath.new(metal_config)
      reload
    end

    attr_reader :manifest

    def reload
      @manifest = Data.load(file_path.staging_manifest)
      @manifest = blank_manifest if @manifest.empty?
    end

    def save
      Data.dump(file_path.staging_manifest, manifest)
    end

    private

    attr_reader :metal_config, :file_path

    def blank_manifest
      { files: [] }
    end
  end
end
