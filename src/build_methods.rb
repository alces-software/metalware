
# frozen_string_literal: true

require 'utils/dynamic_require'
require 'build_methods/build_method'
require 'build_methods/kickstarts/kickstart'

Metalware::Utils::DynamicRequire.relative('build_methods')

module Metalware
  module BuildMethods
    class << self
      def build_method_for(node)
        build_method_class_for(node).new(node)
      end

      private

      def build_method_class_for(node)
        return BuildMethods::Local if node.is_a?(Namespaces::Local)

        case node.config.build_method&.to_sym
        when :local
          raise InvalidLocalBuild,
            "node '#{name}' can not use the local build method"
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
