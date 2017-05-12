
require 'constants'

module Metalware
  class Node
    attr_reader :name

    def initialize(name)
      @name = name
    end

    def hexadecimal_ip
      `gethostip -x #{name} 2>/dev/null`
    end

    def built?
      File.file? build_complete_marker_file
    end

    private

    def build_complete_marker_file
      File.join(Constants::CACHE_PATH, "metalwarebooter.#{name}")
    end
  end
end
