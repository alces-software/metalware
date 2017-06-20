
module Metalware
  # We never want UnsetConfigLogError to be caught
  class UnsetConfigLogError < Exception
    def initialize(msg = "Error in MetalLog. Config not set.")
      super
    end
  end

  class MetalwareError < StandardError
  end

  class NoGenderGroupError < MetalwareError
  end

  class NodeNotInGendersError < MetalwareError
  end

  class SystemCommandError < MetalwareError
  end

  class StrictWarningError < MetalwareError
  end

  class NoRepoError < MetalwareError
  end

  class UnsetParameterAccessError < MetalwareError
  end

  class UnexpectedError < MetalwareError
    def initialize(msg = "An unexpected error has occurred")
      super
    end
  end

  class StatusDataIncomplete < MetalwareError
    def initialize(msg = "Failed to receive data for all nodes")
      super
    end
  end

  class InvalidInput < MetalwareError
  end

  class IterableRecursiveOpenStructPropertyError < MetalwareError
  end

  class YAMLConfigError < MetalwareError
  end

  class UnknownQuestionTypeError < MetalwareError
  end
end
