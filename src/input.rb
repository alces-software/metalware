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

require 'open-uri'
require 'metal_log'

module Metalware
  module Input
    class << self
      def download(from_url, to_path)
        log.info 'Downloading: ' + from_url.to_s
        log.info 'To: ' + to_path.to_s
        open(from_url) do |f|
          File.write(to_path, f.read)
        end
      end

      private

      def log
        @log ||= MetalLog.new('download')
      end
    end

    class Cache
      def initialize
        @cache = {}
      end

      def download(*args)
        key = args.join(' - ')
        save_to_cache(key, args: args)
        result = cache[key]
        result.is_a?(Exception) ? raise(result) : result
      end

      private

      attr_reader :cache

      def save_to_cache(key, args:)
        return if cache[key]
        cache[key] = Input.download(*args)
      rescue StandardError => e
        cache[key] = e
      end
    end
  end
end
