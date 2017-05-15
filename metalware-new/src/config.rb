
require 'yaml'
require 'active_support/core_ext/hash/keys'

require 'constants'
require 'exceptions'


module Metalware
  class Config
    VALUES_WITH_DEFAULTS = {
      build_poll_sleep: 10,
      built_nodes_storage_path: '/var/lib/metalware/cache',
      rendered_files_path: '/var/lib/metalware/rendered',
    }

    def initialize(file)
      file ||= Constants::DEFAULT_CONFIG_PATH
      @config = (
        YAML.load_file(file) || {}
      ).symbolize_keys
    rescue Errno::ENOENT
      raise MetalwareError, "Config file '#{file}' does not exist"
    end

    VALUES_WITH_DEFAULTS.each do |value, default|
      define_method :"#{value}" do
        @config[value] || default
      end
    end
  end
end
