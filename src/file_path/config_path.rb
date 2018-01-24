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
  class FilePath
    class ConfigPath
      attr_reader :base

      def initialize(base:)
        @base = base
      end

      def domain_config
        File.join(base, 'config/domain.yaml')
      end

      def group_config(group)
        File.join(base, 'config', "#{group}.yaml")
      end

      def node_config(node)
        File.join(base, 'config', "#{node}.yaml")
      end

      def local_config
        File.join(base, 'config/local.yaml')
      end
    end
  end
end
