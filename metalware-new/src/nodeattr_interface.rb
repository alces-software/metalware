
require 'constants'
require 'exceptions'

module Metalware
  module NodeattrInterface
    # XXX Move all other interactions with `nodeattr` to this module.
    class << self
      def nodes_in_group(group)
        stdout = `#{Constants::NODEATTR_COMMAND} -c #{group}`
        if stdout.empty?
          raise NoGenderGroupError, "Could not find gender group: #{group}"
        end
        stdout.chomp.split(',')
      end
    end
  end
end
