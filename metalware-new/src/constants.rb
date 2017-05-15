
module Metalware
  module Constants
    METALWARE_INSTALL_PATH = File.absolute_path(File.join(File.dirname(__FILE__), '..'))

    DEFAULT_CONFIG_PATH = File.join(METALWARE_INSTALL_PATH, 'etc/config.yaml')

    METALWARE_DATA_PATH = '/var/lib/metalware'
    # XXX Sometimes this is used and sometimes value from config (which
    # defaults to the same) is used.
    REPO_PATH = File.join(METALWARE_DATA_PATH, 'repo')
    # XXX Ensure created on Metalware install.
    CACHE_PATH = File.join(METALWARE_DATA_PATH, 'cache')

    MAXIMUM_RECURSIVE_CONFIG_DEPTH = 10

    NODEATTR_COMMAND = 'nodeattr'
  end
end
