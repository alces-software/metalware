
# frozen_string_literal: true

module Metalware
  module Namespaces
    class Domain < HashMergerNamespace
      def hostip
        @hostip ||= DeploymentServer.ip
      end

      def hosts_url
        @hosts_url ||= DeploymentServer.system_file_url('hosts')
      end

      def genders_url
        @genders_url ||= DeploymentServer.system_file_url('genders')
      end

      private

      def white_list_for_hasher
        super.concat [:hostip, :hosts_url, :genders_url]
      end

      def hash_merger_input
        {}
      end

      def additional_dynamic_namespace
        {}
      end
    end
  end
end
