
require 'constants'
require 'exceptions'

module Metalware
  module NodeattrInterface
    # XXX Move all other interactions with `nodeattr` to this module.
    class << self
      def nodes_in_group(group)
        stdout = nodeattr("-c #{group}")
        if stdout.empty?
          raise NoGenderGroupError, "Could not find gender group: #{group}"
        end
        stdout.chomp.split(',')
      end

      def groups_for_node(node)
        # If no node passed then it has no groups; without this we would run
        # `nodeattr -l` without args, which would give all groups.
        return [] unless node

        nodeattr("-l #{node}").chomp.split
      rescue SystemCommandError
        raise NodeNotInGendersError, "Could not find node in genders: #{node}"
      end

      private

      def nodeattr(command)
        SystemCommand.run("#{Constants::NODEATTR_COMMAND} #{command}")
      end
    end
  end
end
