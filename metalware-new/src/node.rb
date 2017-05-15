
require 'open3'

require 'constants'
require 'exceptions'

module Metalware
  class Node
    attr_reader :name

    def initialize(config, name)
      @config = config
      @name = name
    end

    def hexadecimal_ip
      # XXX pull this running of external commands out to shared function which
      # is used in other places too? More robust than just using backticks.
      command = "gethostip -x #{name}"
      stdout, stderr, status = Open3.capture3(command)
      if status.exitstatus != 0
        raise MetalwareError, "'#{command}' produced error '#{stderr}'"
      else
        stdout
      end
    end

    def built?
      File.file? build_complete_marker_file
    end

    private

    def build_complete_marker_file
      File.join(@config.built_nodes_storage_path, "metalwarebooter.#{name}")
    end
  end
end
