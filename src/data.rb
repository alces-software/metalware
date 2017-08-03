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

module Metalware
  module Data
    class << self
      def load(data_file)
        data = raw_load(data_file)
        process_loaded_data(data, source: data_file)
      end

      def load_string(data_string)
        data = YAML.load(data_string) || {}
        process_loaded_data(data, source: data_string)
      end

      def dump(data_file, data)
        raise dump_error(data) unless valid_data?(data)
        yaml = data.deep_transform_keys(&:to_s).to_yaml
        File.write(data_file, yaml)
      end

      private

      def raw_load(data_file)
        if File.file? data_file
          YAML.load_file(data_file) || {}
        else
          {}
        end
      end

      def process_loaded_data(data, source:)
        raise load_error(source) unless valid_data?(data)
        data.deep_transform_keys(&:to_sym)
      end

      def valid_data?(data)
        data.respond_to? :deep_transform_keys
      end

      def load_error(data_file)
        raise DataError, "Attempted to load invalid data from #{data_file}; should contain a hash"
      end

      def dump_error(data)
        raise DataError, "Attempted to dump invalid data (#{data}); should be a hash"
      end
    end
  end
end
