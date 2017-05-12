
module Metalware
  class Node
    attr_reader :name

    def initialize(name)
      @name = name
    end

    def hexadecimal_ip
      `gethostip -x #{name} 2>/dev/null`
    end
  end
end
