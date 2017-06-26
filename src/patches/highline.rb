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
module Metalware
  module Patches
    module HighLine
      module Questions
        def sanitize_default_erb_tags
          @sanitized_default ||= @default.gsub("<%", "<%%")
        end

        def append_default(  )
          if @question =~ /([\t ]+)\Z/
            @question << "|#{sanitize_default_erb_tags}|#{$1}"
          elsif @question == ""
            @question << "|#{sanitize_default_erb_tags}|  "
          elsif @question[-1, 1] == "\n"
            @question[-2, 0] =  "  |#{sanitize_default_erb_tags}|"
          else
            @question << "  |#{sanitize_default_erb_tags}|"
          end
        end
      end
    end
  end
end