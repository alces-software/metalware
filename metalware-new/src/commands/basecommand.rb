
module Metalware
  module Commands
    class BaseCommand
      def initialize(args, options)
        setup(args, options)
        run
      rescue Interrupt => e
        handle_interrupt(e)
      end

      private

      def setup(args, options)
        raise NotImplementedError
      end

      def run
        raise NotImplementedError
      end

      def handle_interrupt(e)
        raise e
      end
    end
  end
end
