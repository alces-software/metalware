
# frozen_string_literal: true

require 'build_methods'

module Metalware
  module BuildMethods
    module Kickstarts
      class Kickstart < BuildMethod
        def start_hook
          render_pxelinux(firstboot: true)
        end

        def complete_hook
          render_pxelinux(firstboot: false)
        end

        def dependency_paths
          super.push(strip_leading_repo_path(pxelinux_template_path))
        end

        private

        def staging_templates
          [:kickstart]
        end

        def render_pxelinux(parameters)
          Templater.render_to_file(
            node,
            pxelinux_template_path,
            save_path,
            dynamic: parameters
          )
        end

        def pxelinux_template_path
          raise NotImplementedError
        end

        def save_path
          raise NotImplementedError
        end
      end
    end
  end
end
