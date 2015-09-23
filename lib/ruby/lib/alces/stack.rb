#==============================================================================
# Copyright (C) 2007-2015 Stephen F. Norledge and Alces Software Ltd.
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
require 'alces/tools/config'
require 'yaml'

module Alces
  module Stack
    class Configuration < Struct.new(:log_root, :ssl_root, :etc_root)
      def initialize(h)
        h.each {|k,v| self[k] = v}
      end
    end

    class << self
      def config
        @config ||= Configuration.new(default_config.merge(load_config))
      end

      def default_config
        {
          'log_root' => '/var/log/alces/tools',
          'ssl_root' => '/opt/metalware/etc/ssl',
          'etc_root' => '/opt/metalware/etc'
        }
      end

      def load_config
        YAML.load_file(Alces::Tools::Config.find('stack.yml'))
      rescue
        {}
      end
    end
  end
end
