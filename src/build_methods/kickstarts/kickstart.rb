
# frozen_string_literal: true

require 'build_methods'

module Metalware
  module BuildMethods
    module Kickstarts
      class Kickstart < BuildMethod
        # Defines the TEMPLATES for the kickstart build method
        def initialize(*a)
          unless self.class.const_defined?('TEMPLATES')
            templates = [:kickstart, self.class::REPO_DIR].freeze
            self.class.const_set('TEMPLATES', templates)
          end
          super
        end

        def render_build_complete_templates
          render_pxelinux(DEFAULT_BUILD_COMPLETE_PARAMETERS)
        end

        private

        def staging_templates
          [:kickstart]
        end

        def render_pxelinux(parameters)
          render_template(pxelinux_repo_dir,
                          parameters: parameters,
                          save_path: save_path)
        end

        def pxelinux_repo_dir
          self.class::REPO_DIR
        end

        def save_path
          raise NotImplementedError
        end
      end
    end
  end
end
