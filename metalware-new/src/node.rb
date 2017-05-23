
require 'open3'

require 'constants'
require 'system_command'

module Metalware
  class Node
    attr_reader :name

    def initialize(config, name)
      @config = config
      @name = name
    end

    def hexadecimal_ip
      SystemCommand.run "gethostip -x #{name}"
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
