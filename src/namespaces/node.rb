
# frozen_string_literal: true

require 'build_methods'

module Metalware
  module Namespaces
    class Node < HashMergerNamespace
      attr_reader :name

      def group
        @group ||= alces.groups.send(genders.first)
      end

      def genders
        @genders ||= NodeattrInterface.groups_for_node(name)
      end

      def index
        @index ||= begin
          group.nodes.each_with_index do |other_node, index|
            return(index + 1) if other_node == self
          end
          raise InternalError, 'Node does not appear in its primary group'
        end
      end

      def ==(other)
        return false unless other.is_a?(Node)
        other.name == name
      end

      def kickstart_url
        @kickstart_url ||= DeploymentServer.kickstart_url(name)
      end

      def build_complete_url
        @build_complete_url ||= DeploymentServer.build_complete_url(name)
      end

      def genders_url
        @genders_url ||= DeploymentServer.system_file_url('genders')
      end

      def hexadecimal_ip
        @hexadecimal_ip ||= SystemCommand.run "gethostip -x #{name}"
      end

      def build_method
        validate_build_method

        case config.build_method
        when :'uefi-kickstart'
          BuildMethods::Kickstarts::UEFI
        when :basic
          BuildMethods::Basic
          # TODO: the self node is currently not supported
          # when :self
          #  BuildMethods::Self
        else
          BuildMethods::Kickstarts::Pxelinux
          # self_node? ? BuildMethods::Self : BuildMethods::Kickstarts::Pxelinux
        end
      end

      private


      def hash_merger_input
        { groups: genders, node: name }
      end

      def additional_dynamic_namespace
        { node: self }
      end

      def validate_build_method
        return if 'Break statement until self is supported'.to_s
        # TODO: Does not support self node
        if self_node?
          unless [:self, nil].include?(repo_build_method)
            raise SelfBuildMethodError, build_method: repo_build_method
          end
        elsif repo_build_method == :self
          raise SelfBuildMethodError, building_self_node: false
        end
      end
    end
  end
end
