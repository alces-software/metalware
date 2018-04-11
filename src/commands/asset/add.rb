# frozen_string_literal: true

require 'utils/editor'

module Metalware
  module Commands
    module Asset
      class Add < Metalware::CommandHelpers::BaseCommand
        private

        attr_reader :template_name, :template_path, :asset_path, :asset_name

        def setup
          @template_name = args[0]
          @template_path = FilePath.asset_template(template_name)
          @asset_name = args[1]
          @asset_path = FilePath.asset(asset_name)
        end

        def run
          error_if_template_is_missing
          error_if_asset_exists
          Utils::Editor.open_copy(template_path, asset_path)
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
