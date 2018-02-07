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

require 'yaml'
require 'active_support/core_ext/hash/keys'
require 'active_support/core_ext/string/filters'

require 'constants'
require 'exceptions'
require 'ostruct'
require 'metal_log'
require 'data'

module Metalware
  class Config
    attr_reader :cli

    # XXX DRY these paths up.
    # XXX Maybe move all these paths into Constants and then reference them here
    KEYS_WITH_VALUES = {
      validation: true,
      build_poll_sleep: 10,
      log_severity: 'INFO',
    }.freeze

    # TODO: Remove the file input for configs. Always use the default
    def initialize(_remove_this_file_input = nil, options = {})
      file = Constants::DEFAULT_CONFIG_PATH
      raise MetalwareError, "Config file '#{file}' does not exist" unless File.file?(file)

      @cli = OpenStruct.new(options)
      define_keys_with_values
    end

    private

    def define_keys_with_values
      KEYS_WITH_VALUES.each do |key, default|
        define_singleton_method :"#{key}" { default }
      end
    end
  end
end
