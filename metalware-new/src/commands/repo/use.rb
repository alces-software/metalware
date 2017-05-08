
module Metalware
  module Commands
    module Repo
      class Use
	def initialize(args, options)
	  puts "Running repo use with args #{args.inspect} and options #{options.inspect}"
	end
      end
    end
  end
end
