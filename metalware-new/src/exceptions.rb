
module Metalware
	# We never want UnsetConfigLogError to be caught
  class UnsetConfigLogError < Exception
  	def initialize(msg = "Config not found in MetalLog, reverting to default")
  		super
  	end
  end

  class MetalwareError < StandardError
  end

  class NoGenderGroupError < MetalwareError
  end

  class SystemCommandError < MetalwareError
  end
end
