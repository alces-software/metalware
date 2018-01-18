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

module Metalware
  module Plugins
    Plugin = Struct.new(:path) do
      def name
        path.basename.to_s
      end

      def enabled?
        Plugins.enabled?(name)
      end

      def enabled_identifier
        if enabled?
          '[ENABLED]'.green
        else
          '[DISABLED]'.red
        end
      end

      def enable!
        Plugins.enable!(name)
      end

      def configure_questions
        Plugins::ConfigureQuestionsBuilder.build(self)
      end

      def enabled_question_identifier
        Plugins.enabled_question_identifier(name)
      end
    end
  end
end
