
# frozen_string_literal: true

#==============================================================================
# Copyright (C) 2017 Stephen F. Norledge and Alces Software Ltd.
#
# This file/package is part of Alces Metalware.
#
# Alces Metalware is free software: you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License
# as published by the Free Software Foundation, either version 3 of
# the License, or (at your option) any later version.
#
# Alces Metalware is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this package.  If not, see <http://www.gnu.org/licenses/>.
#
# For more information on the Alces Metalware, please visit:
# https://github.com/alces-software/metalware
#==============================================================================

require 'erb'

module Metalware
  module Templating
    module Renderer
      class << self
        def replace_erb_with_binding(template, parameters_binding)
          render_erb_template(template, parameters_binding)
        end

        private

        def render_erb_template(template, binding)
          # This mode allows templates to prevent inserting a newline for a
          # given line by ending the ERB tag on that line with `-%>`.
          trim_mode = '-'

          safe_level = 0
          erb = ::ERB.new(template, safe_level, trim_mode)

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
