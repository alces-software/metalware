
# frozen_string_literal: true

module Metalware
  module Templating
    module Renderer
      class << self
        # Replace all ERB in given template, generating the binding to use from
        # the given parameters.
        def replace_erb(template, parameter_binding)
          render_erb_template(template, parameter_binding)
        
          # TODO: Move NoMethodError into BindingWrapper
        rescue NoMethodError => e
          # May be useful to include the name of the unset parameter in this error,
          # however this is tricky as by the time we attempt to access a method on
          # it the unset parameter is just `nil` as far as we can see here.
          raise UnsetParameterAccessError,
                "Attempted to call method `#{e.name}` of unset template parameter"
        end

        private

        def render_erb_template(template, binding)
          # This mode allows templates to prevent inserting a newline for a given
          # line by ending the ERB tag on that line with `-%>`.
          trim_mode = '-'

          safe_level = 0
          erb = ERB.new(template, safe_level, trim_mode)

          begin
            erb.result(binding)
          rescue SyntaxError => error
            handle_error_rendering_erb(template, error)
          end
        end

        def handle_error_rendering_erb(template, error)
          Output.stderr "\nRendering template failed!\n\n"
          Output.stderr "Template:\n\n"
          Output.stderr_indented_error_message template
          Output.stderr "\nError message:\n\n"
          Output.stderr_indented_error_message error.message
          abort
        end
      end
    end
  end
end
