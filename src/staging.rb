# frozen_string_literal: true

require 'data'
require 'file_path'
require 'recursive-open-struct'
require 'templater'
require 'managed_file'

module Metalware
  class Staging
    def self.update
      staging = new
      yield staging if block_given?
    ensure
      staging&.save
    end

    def self.template
      update do |staging|
        templater = Templater.new(staging)
        if block_given?
          yield templater
        else
          templater
        end
      end
    end

    def self.manifest
      new.manifest
    end

    private_class_method :new

    def save
      Data.dump(FilePath.staging_manifest, manifest.to_h)
    end

    def manifest
      @manifest ||= begin
        Data.load(FilePath.staging_manifest).tap do |x|
          x.merge! blank_manifest if x.empty?
          # Converts the file paths to strings
          x[:files] = x[:files].map { |key, data| [key.to_s, data] }.to_h
        end
      end
    end

    def push_file(sync, content, **options)
      staging = FilePath.staging(sync)
      FileUtils.mkdir_p(File.dirname(staging))
      File.write(staging, content)
      manifest[:files][sync] = default_push_options.merge(options)
    end

    def delete_file_if
      manifest[:files].delete_if do |sync_path, raw_data|
        ret = nil
        begin
          data = OpenStruct.new(raw_data.merge(sync: sync_path))
          data.content = file_content(data)
          ret = yield OpenStruct.new(data)
        rescue StandardError => e
          MetalLog.warn e.inspect
          ret = false
        end
        FileUtils.rm FilePath.staging(sync_path) if ret
        ret
      end
    end

    def push_service(service)
      services = manifest[:services]
      services.push(service) unless services.include? service
    end

    def delete_service_if
      manifest[:services].delete_if { |service| yield service }
    end

    private

    def default_push_options
      {
        managed: false,
        validator: nil,
      }
    end

    def blank_manifest
      { files: {}, services: [] }
    end

    def file_content(data)
      raw = File.read(FilePath.staging(data.sync))
      data.managed ? managed_file_content(data, raw) : raw
    end

    def managed_file_content(data, rendered_content)
      managed_file_content_args = [data.sync, rendered_content]
      if data.comment_char
        managed_file_content_args.push(comment_char: data.comment_char)
      end
      ManagedFile.content(*managed_file_content_args)
    end
  end
end
