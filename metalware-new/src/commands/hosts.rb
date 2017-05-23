
module Metalware
  module Commands
    class Hosts
      def initialize(args, options)
        options.default template: 'default'

        puts "Running hosts with args #{args.inspect} and options #{options.inspect}"
      end
    end
  end
end
