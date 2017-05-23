
module Metalware
  module Commands
    class Hunter
      def initialize(args, options)
        options.default \
          interface: 'eth0',
          prefix: 'node',
          length: 2,
          start: 1

        puts "Running hunter with args #{args.inspect} and options #{options.inspect}"
      end
    end
  end
end
