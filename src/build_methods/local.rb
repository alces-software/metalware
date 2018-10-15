
# frozen_string_literal: true

require 'system_command'
require 'fileutils'

module Metalware
  module BuildMethods
    class Local < BuildMethod
      def start_hook
        super
        rendered_local_template =
          file_path.template_save_path(:local, node: node)
        FileUtils.chmod 'u+x', rendered_local_template
        puts SystemCommand.run(rendered_local_template)
      end

      private

      def staging_templates
        [:local]
      end
    end
  end
end
