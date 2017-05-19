
# XXX Worth logging when outputting in this module as well?
module Metalware
  module Output
    class << self
      def stderr(*lines)
        # Don't output anything in unit tests to prevent noise.
        if $0 !~ /rspec$/
          STDERR.puts(*lines)
        end
      end

      def stderr_indented_error_message(text)
        stderr text.gsub(/^/, '>>> ')
      end
    end
  end
end
