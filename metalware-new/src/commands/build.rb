
module Metalware
  module Commands
    class Build
      def initialize(args, options)
        options.default \
          kickstart: 'default',
          pxelinux: 'default'

        puts "Running build with args #{args.inspect} and options #{options.inspect}"
      end
    end
  end
end
