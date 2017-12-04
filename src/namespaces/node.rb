
# frozen_string_literal: true

require 'build_methods'
require 'build_files_retriever'

module Metalware
  module Namespaces
    class Node < HashMergerNamespace
      class << self
        def create(alces, name)
          name == 'local' ? Local.create(alces, name) : new(alces, name)
        end

        private

        def new(*args)
          super(*args)
        end
      end

      include Namespaces::Mixins::Name

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

      def kickstart_url
        @kickstart_url ||= DeploymentServer.kickstart_url(name)
      end

      def build_complete_path
        @build_complete_path ||= FilePath.new(metal_config)
                                         .build_complete(name)
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
        @build_method ||= build_method_class.new(alces.metal_config, self)
      end

      def files
        @files ||= begin
          data = alces.build_files_retriever.retrieve(self)
          Constants::HASH_MERGER_DATA_STRUCTURE.new(data, &template_block)
        end
      end

      private

      def white_list_for_hasher
        super.concat([
                       :group,
                       :genders,
                       :index,
                       :kickstart_url,
                       :build_complete_url,
                       :build_complete_path,
                       :hexadecimal_ip,
                       :build_method,
                     ])
      end

      def recursive_white_list_for_hasher
        super.push(:files)
      end

      def hash_merger_input
        { groups: genders, node: name }
      end

      def additional_dynamic_namespace
        { node: self }
      end

      def build_method_class
        case config.build_method
        when :local
          msg = "node '#{name}' can not use the local build"
          raise InvalidLocalBuild, msg
        when :'uefi-kickstart'
          BuildMethods::Kickstarts::UEFI
        when :basic
          BuildMethods::Basic
        else
          BuildMethods::Kickstarts::Pxelinux
        end
      end
    end
  end
end
