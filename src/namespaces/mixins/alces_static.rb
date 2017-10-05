# frozen_string_literal: true

module Metalware
  module Namespaces
    module Mixins
      module AlcesStatic
        def alces
          self
        end

        def nodes
          @nodes ||= begin
            arr = NodeattrInterface.all_nodes.map do |node_name|
              Namespaces::Node.new(alces, node_name)
            end
            Namespaces::MetalArray.new(arr)
          end
        end
      end
    end
  end
end
