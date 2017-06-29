
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

  class CombineConfigError < MetalwareError
    def intialize(msg="Could not combine config hashes")
      super
    end
  end

  class UnknownQuestionTypeError < MetalwareError
  end

  class LoopErbError < MetalwareError
    def initialize(msg="Input hash may contain infinitely recursive ERB")
      super
    end
  end

  class MissingParameter < MetalwareError
  end
end
