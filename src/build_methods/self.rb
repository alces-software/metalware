
# frozen_string_literal: true

require 'system_command'
require 'fileutils'

module Metalware
  module BuildMethods
    class Self < BuildMethod
      TEMPLATES = [:self].freeze

      def render_build_started_templates(parameters)
        render_template(:self, parameters: parameters)
      end

      def start_build
        rendered_self_template = file_path.template_save_path(:self, node: node)
        FileUtils.chmod 'u+x', rendered_self_template
        puts SystemCommand.run(rendered_self_template)
      end

      def render_build_complete_templates(_parameters); end
    end
  end
end
