# frozen_string_literal: true

module Metalware
  module Namespaces
    module Mixins
      module AlcesPermanentNamespace
        def alces
          self
        end

        def nodes
          @nodes ||= NodeattrInterface
                     .all_nodes
                     .map do |node_name|
            Namespaces::Node.new(self, node_name)
          end
        end
      end
    end
  end
end
