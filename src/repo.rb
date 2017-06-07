
require 'constants'


module Metalware
  class Repo
    attr_reader :path

    def initialize(path)
      @path = path
    end

    def exists?
      Dir.exist? path
    end
  end
end
