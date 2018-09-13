
# frozen_string_literal: true

require 'build_methods'

module Metalware
  module BuildMethods
    module Kickstarts
      class Kickstart < BuildMethod
        def start_hook
          super
          render_pxelinux(firstboot: true)
        end

        def complete_hook
          super
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
          rendered_content = Templater.render(node,
                                              pxelinux_template_path,
                                              **parameters)
          File.open(save_path, 'w') do |f|
            f.write(rendered_content)
            f.fdatasync
          end
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
