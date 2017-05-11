
require 'constants'

module Metalware
  module NodeattrInterface
    # XXX Move all other interactions with `nodeattr` to this module.
    class << self
      def nodes_in_group(group)
        `#{Constants::NODEATTR_COMMAND} -c #{group}`.chomp.split(',')
      end
    end
  end
end
