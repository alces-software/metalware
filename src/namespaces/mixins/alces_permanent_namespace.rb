# frozen_string_literal: true

module Metalware
  module Namespaces
    module Mixins
      module AlcesPermanentNamespace
        def alces
          self
        end

        def nodes
          @nodes = Namespaces::Nodes.new
        end
      end
    end
  end
end
