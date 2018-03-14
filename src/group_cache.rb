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

require 'validation/loader'
require 'data'

module Metalware
  class GroupCache
    include Enumerable

    def self.update
      cache = new
      yield cache
      cache.save
    end

    def initialize(force_reload_file: false)
      @force_reload = force_reload_file
    end

    def group?(group)
      primary_groups.include? group
    end

    def add(group)
      return if group?(group)
      primary_groups_hash[group.to_sym] = next_available_index
      bump_next_index
    end

    def remove(group)
      pgh = primary_groups_hash
      pgh.delete(group.to_sym)
    end

    def each
      primary_groups.each do |group_name|
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

    def primary_groups
      primary_groups_hash.keys.map(&:to_s)
    end

    def next_available_index
      data[:next_index]
    end

    def orphans
      data[:orphans]
    end

    def push_orphan(name)
      return if orphans.include?(name)
      orphans.push(name)
    end

    def save
      groups_hash = primary_groups_hash.dup.tap { |x| x.delete(:orphan) }
      payload = {
        next_index: next_available_index,
        primary_groups: groups_hash,
        orphans: orphans,
      }
      Data.dump(file_path.group_cache, payload)
      @data = nil # Reloads the cached file
      data
    end

    private

    attr_reader :force_reload

    def loader
      @loader ||= Validation::Loader.new
    end

    def file_path
      @file_path ||= FilePath
    end

    def load
      loader.group_cache.tap do |d|
        if d.empty?
          d.merge!(next_index: 1,
                   primary_groups: {},
                   orphans: [])
        end
      end
    end

    def data
      force_reload ? load : @data ||= load
    end

    def primary_groups_hash
      @primary_groups_hash ||= begin
        data[:primary_groups][:orphan] = 0
        data[:primary_groups]
      end
    end

    def bump_next_index
      data[:next_index] += 1
    end
  end
end
