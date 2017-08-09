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

require 'config'
require 'validator/loader'
require 'data'

module Metalware
  class GroupCache
    def initialize(metalware_config)
      @config = metalware_config
    end

    def is_group?(group)
      primary_groups.include? group
    end

    def add(group)
      new_groups = primary_groups << group
      Data.dump(file_path.group_cache, primary_groups: new_groups)
      force_reload_cache_data
    end

    def remove(delete_group)
      new_cache = primary_groups.reject { |group| group == delete_group }
      Data.dump(file_path.group_cache, primary_groups: new_cache)
      force_reload_cache_data
    end

    private

    attr_reader :config
  
    def loader
      @loader ||= Validator::Loader.new(config)
    end

    def file_path
      @file_path ||= FilePath.new(config)
    end

    def data
      @data ||= loader.group_cache
    end

    def force_reload_cache_data
      @data = nil
      data
    end

    def primary_groups
      data[:primary_groups] || []
    end
  end
end