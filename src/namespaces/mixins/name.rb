
# frozen_string_literal: true

module Metalware
  module Namespaces
    module Mixins
      module Name
        attr_reader :name

        def to_s
          super.chomp('>') + ", name: #{name}>"
        end

        def ==(other)
          return false unless other.is_a?(self.class)
          other.name == name
        end
      end
    end
  end
end
