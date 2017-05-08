
module Metalware
  module Commands
    module Repo
      class Update
	def initialize(args, options)
	  puts "Running repo update with args #{args.inspect} and options #{options.inspect}"
	end
      end
    end
  end
end
