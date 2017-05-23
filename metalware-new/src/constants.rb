
module Metalware
  module Constants
    METALWARE_INSTALL_PATH = File.join(File.dirname(__FILE__), '..')

    METALWARE_DATA_PATH = '/var/lib/metalware'
    REPO_PATH = File.join(METALWARE_DATA_PATH, 'repo')
    # XXX Ensure created on Metalware install.
    CACHE_PATH = File.join(METALWARE_DATA_PATH, 'cache')

    MAXIMUM_RECURSIVE_CONFIG_DEPTH = 10

    NODEATTR_COMMAND = 'nodeattr'
  end
end
