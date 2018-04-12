# frozen_string_literal: true

require 'utils/editor'

module Metalware
  module Commands
    module Asset
      class Add < Metalware::CommandHelpers::BaseCommand
        include CommandHelpers::AssetHelper

        private

        attr_reader :template_name, :template_path, :asset_path, :asset_name

        def setup
          @template_name = args[0]
          @template_path = FilePath.asset_template(template_name)
          @asset_name = args[1]
          @asset_path = FilePath.asset(asset_name)
          unpack_node_from_options
        end

        def run
          error_if_template_is_missing
          error_if_asset_exists
          copy_and_edit_asset_file(template_path, asset_path)
          assign_asset_to_node_if_given(asset_name)
        end

        def error_if_template_is_missing
          return if File.exist?(template_path)
          raise InvalidInput, <<-EOF.squish
            Cannot find asset template: "#{template_name}"
          EOF
        end

        def error_if_asset_exists
          return unless File.exist?(asset_path)
          raise InvalidInput, <<-EOF.squish
            The "#{asset_name}" asset already exists. Please use `metal
            asset edit` instead
          EOF
        end
      end
    end
  end
end
