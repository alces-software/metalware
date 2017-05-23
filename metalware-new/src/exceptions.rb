
module Metalware
  class MetalwareError < StandardError
  end

  class NoGenderGroupError < MetalwareError
  end

  class SystemCommandError < MetalwareError
  end
end
