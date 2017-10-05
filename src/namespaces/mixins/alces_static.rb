# frozen_string_literal: true

module Metalware
  module Namespaces
    module Mixins
      module AlcesStatic
        def alces
          self
        end

        def nodes
          @nodes ||= Namespaces::Nodes.new(self)
        end
      end
    end
  end
end
