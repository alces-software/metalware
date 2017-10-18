
# frozen_string_literal: true

require 'system_command'
require 'fileutils'

module Metalware
  module BuildMethods
    class Local < BuildMethod
      TEMPLATES = [:local].freeze

      def render_build_start_templates
        render_template(:local, parameters: DEFAULT_BUILD_START_PARAMETERS)
      end

      def start_build
        rendered_self_template =
          file_path.template_save_path(:local, node: node)
        FileUtils.chmod 'u+x', rendered_self_template
        puts SystemCommand.run(rendered_self_template)
      end
    end
  end
end
