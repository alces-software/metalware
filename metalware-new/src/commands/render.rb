
module Metalware
  module Commands
    class Render
      def initialize(args, options)
        puts "Running render with args #{args.inspect} and options #{options.inspect}"
      end
    end
  end
end
