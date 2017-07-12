
require 'hashie'
require 'active_support/core_ext/hash'

require "constants"
require 'deployment_server'
require 'nodeattr_interface'
require 'templating/missing_parameter_wrapper'


module Metalware
  module Templating
    class MagicNamespace
      def initialize(config:, node: nil, firstboot: nil, files: nil)
        @metalware_config = config
        @node = node
        @firstboot = firstboot
        @files = Hashie::Mash.new(files) if files
      end

      attr_reader :firstboot, :files
      delegate :index, to: :node

      def group_index
        node.group_index
      rescue UnconfiguredGroupError
        # If the node's primary group is not configured yet, return nil rather
        # than blow up.
        nil
      end

      def nodename
        node.name
      end

      def answers
        MissingParameterWrapper.new(node.answers, raise_on_missing: true)
      end

      def genders
        # XXX Do we want to make genders available as a `Hashie::Mash` too?
        # Depends if we want to be able to iterate through genders or just get
        # list of nodes in a specified gender
        GenderGroupProxy
      end

      def hunter
        if File.exist? Constants::HUNTER_PATH
          Hashie::Mash.load(Constants::HUNTER_PATH)
        else
          warning = \
            "#{Constants::HUNTER_PATH} does not exist; need to run " +
            "'metal hunter' first. Falling back to empty hash for alces.hunter."
          MetalLog.warn warning
          Hashie::Mash.new
        end
      end

      def hosts_url
        DeploymentServer.system_file_url 'hosts'
      end

      def genders_url
        DeploymentServer.system_file_url 'genders'
      end

      def kickstart_url
        DeploymentServer.kickstart_url(nodename)
      end

      def build_complete_url
        DeploymentServer.build_complete_url(nodename)
      end

      def hostip
        DeploymentServer.ip
      end

      private

      attr_reader :metalware_config, :node

      module GenderGroupProxy
        class << self
          def method_missing(group_symbol)
            NodeattrInterface.nodes_in_group(group_symbol)
          rescue NoGenderGroupError => error
            warning = "#{error}. Falling back to empty array for alces.#{group_symbol}."
            MetalLog.warn warning
            []
          end
        end
      end

    end
  end
end
