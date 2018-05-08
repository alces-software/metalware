
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

require 'templater'
require 'exceptions'
require 'metal_log'
require 'file_path'

module Metalware
  module DNS
    class Hosts
      def self.restart_service
        MetalLog.warn <<-EOF.squish
          DNS::Hosts does not currently support restarting services
        EOF
      end

      def initialize(alces, templater)
        @alces = alces
        @templater = templater
      end

      def update
        templater.render(alces, template, rendered_path, **staging_options)
      end

      private

      attr_reader :alces, :templater

      def template
        FilePath.template_path('hosts', node: alces.domain)
      end

      def rendered_path
        FilePath.hosts
      end

      def staging_options
        {
          service: self.class.name,
          managed: true,
        }
      end
    end
  end
end
