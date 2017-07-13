
module Metalware
  module Templating
    class GroupNamespace
      attr_reader :name
      delegate :answers, to: :templating_configuration

      def initialize(metalware_config, group_name)
        @metalware_config = metalware_config
        @name = group_name
      end

      private

      attr_reader :metalware_config

      def templating_configuration
        @templating_configuration ||=
          Configuration.for_primary_group(name, config: metalware_config)
      end
    end
  end
end
