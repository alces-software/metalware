
require 'exceptions'


module Metalware
  module SystemCommand
    class << self
      # This is just a slightly more robust version of Kernel.`, so we get an
      # exception that must be handled or be displayed if the command run
      # fails.
      def run(command)
        stdout, stderr, status = Open3.capture3(command)
        if status.exitstatus != 0
          raise SystemCommandError,
            "'#{command}' produced error '#{stderr.strip}'"
        else
          stdout
        end
      end
    end
  end
end
