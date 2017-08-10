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
    include Enumerable

    def initialize(metalware_config)
      @config = metalware_config
    end

    def is_group?(group)
      primary_groups_as_str.include? group
    end

    def add(group)
      new_groups = primary_groups_hash.merge({
        group.to_sym => next_available_index
      })
      save(next_available_index + 1, new_groups)
    end

    def remove(group)
      primary_groups_hash.delete(group.to_sym)
      save(next_available_index, primary_groups_hash)
    end

    def each
      primary_groups_as_str.each do |group_name|
        yield group_name
      end
    end

    # Has been overridden so the hash behaves as if it was an array
    def each_with_index
      primary_groups_hash.each { |group, idx| yield(group.to_s, idx) }
    end

    def index(group)
      primary_groups_hash[group&.to_sym]
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
      @data ||= loader.group_cache.tap do |d|
        if d.empty?
          d.merge!({
            next_index: 0,
            primary_groups: {}
          })
        end
      end
    end

    def primary_groups_hash
      data[:primary_groups]
    end

    def primary_groups_as_str
      primary_groups_hash.keys.map(&:to_s)
    end

    def next_available_index
      data[:next_index]
    end

    def save(next_index, group_hash)
      payload = {
        next_index: next_index,
        primary_groups: group_hash
      }
      Data.dump(file_path.group_cache, payload)
      @data = nil # Reloads the cached file
      data
    end
  end
end