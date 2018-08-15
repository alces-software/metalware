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

require 'active_support/core_ext/string/strip'
require 'active_support/core_ext/string/filters'

require 'constants'
require 'metal_log'
require 'exceptions'
require 'utils'
require 'data'
require 'staging'

module Metalware
  class Templater
    class << self
      def render(namespace, template, **dynamic_namespace)
        raw_template = File.read(template)
        begin
          namespace.render_erb_template(raw_template, dynamic_namespace)
        rescue StandardError => e
          msg = "Failed to render template: #{template}"
          raise e, "#{msg}\n#{e}", e.backtrace
        end
      end
    end

    def initialize(staging)
      @staging = staging
    end

    def render(
      namespace,
      template,
      sync_location,
      dynamic: {},
      **staging_options
    )
      rendered = self.class.render(namespace, template, dynamic)
      staging.push_file(sync_location, rendered, **staging_options)
    end

    private

    attr_reader :staging
  end
end
