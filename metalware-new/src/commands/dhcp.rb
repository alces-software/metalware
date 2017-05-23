
module Metalware
  module Commands
    class Dhcp
      def initialize(args, options)
        options.default template: 'default'

        puts "Running dhcp with args #{args.inspect} and options #{options.inspect}"
      end
    end
  end
end
