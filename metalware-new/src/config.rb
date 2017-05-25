
require 'yaml'
require 'active_support/core_ext/hash/keys'

require 'constants'
require 'exceptions'


module Metalware
  class Config
    # XXX DRY these paths up.
    VALUES_WITH_DEFAULTS = {
      build_poll_sleep: 10,
      built_nodes_storage_path: '/var/lib/metalware/cache/built-nodes',
      rendered_files_path: '/var/lib/metalware/rendered',
      pxelinux_cfg_path: '/var/lib/tftpboot/pxelinux.cfg',
      repo_path: '/var/lib/metalware/repo',
      log_path: '/var/log/metalware',
      log_serverity: "INFO",
      repo_configs_path: '/var/lib/metalware/repo/config/',
    }

    def initialize(file=nil)
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

    def repo_config_path(config_name)
      config_file = config_name + '.yaml'
      File.join(repo_configs_path, config_file)
    end
  end
end
