
# frozen_string_literal: true

module Metalware
  # An easily stubbable module to handle certain behaviour which is hard to
  # test directly, so we can just test this receives correct messages.
  module Io
    class << self
      def abort(*args)
        # If we're in a unit test, raise so we can clearly tell an unexpected
        # `abort` occurred, rather than aborting the test suite.
        raise AbortInTestError, *args if $PROGRAM_NAME.match?(/rspec$/)
        Kernel.abort(*args)
      end
    end
  end
end
