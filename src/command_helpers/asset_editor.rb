# frozen_string_literal: true

require 'asset_builder'

module Metalware
  module CommandHelpers
    class AssetEditor < BaseCommand
      private

      attr_reader :asset_name

      def run
        edit_first_asset
        build_sub_assets
        assign_asset_to_node_if_given
      end

      def edit_first_asset
        raise NotImplementedError
      end

      def build_sub_assets
        while (asset = asset_builder.pop_asset)
          ask_edit_asset(asset.name) ? asset.edit_and_save : asset.save
        end
      end

      def ask_edit_asset(name)
        highline.agree <<-EOF.squish
          Do you wish to edit asset "#{name}"? [yes/no]
        EOF
      end

      def asset_builder
        @asset_builder ||= AssetBuilder.new
      end

      def highline
        @highline ||= HighLine.new
      end

      def node
        @node ||= begin
           if options.node
             alces.nodes.find_by_name(options.node).tap do |n|
               raise_error_if_node_is_missing(n)
             end
           end
         end
      end

      def assign_asset_to_node_if_given
        return unless node
        Cache::Asset.update do |cache|
          cache.assign_asset_to_node(asset_name, node)
        end
      end

      def raise_error_if_node_is_missing(node_input)
        return if node_input
        raise InvalidInput, <<-EOF
          Unable to find node: #{options.node}
        EOF
      end
    end
  end
end
