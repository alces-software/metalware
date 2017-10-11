
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

        def render_build_started_templates(parameters)
          render_kickstart(parameters)
          render_pxelinux(parameters)
        end

        def render_build_complete_templates(parameters)
          render_pxelinux(parameters)
        end

        private

        def render_kickstart(parameters)
          render_template(:kickstart, parameters: {})#TODO: parameters)
        end

        def render_pxelinux(parameters)
          render_template(pxelinux_repo_dir,
                          # TODO: Are the parameters still required?
                          parameters: {},#parameters,
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
