# frozen_string_literal: true

require 'utils/editor'

module Metalware
  module Commands
    module Asset
      class Add < Metalware::CommandHelpers::BaseCommand
        private

        attr_reader :template_name, :template_path, :asset_path

        def setup
          @template_name = args[0]
          @template_path = FilePath.asset_template(template_name)
          @asset_path = FilePath.asset(args[1])
        end

        def run
          error_if_template_is_missing
          Utils::Editor.open_copy(template_path, asset_path)
        end

        def error_if_template_is_missing
          return if File.exist?(template_path)
          raise InvalidInput, <<-EOF.squish
            Can not find asset template: "#{template_name}"
          EOF
        end
      end
    end
  end
end

