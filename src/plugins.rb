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
  module Plugins
    class << self
      include Enumerable

      def each
        plugin_directories.each do |dir|
          plugin = Plugin.new(dir)
          yield(plugin)
        end
      end

      def enabled?(plugin_name)
        enabled_plugin_names.include?(plugin_name)
      end

      def enable!(plugin_name)
        validate_plugin_exists!(plugin_name)
        return if enabled?(plugin_name)

        new_enabled_plugins = enabled_plugin_names + [plugin_name]
        update_enabled_plugins!(new_enabled_plugins)
      end

      def disable!(plugin_name)
        validate_plugin_exists!(plugin_name)

        new_enabled_plugins = enabled_plugin_names.reject do |name|
          name == plugin_name
        end
        update_enabled_plugins!(new_enabled_plugins)
      end

      private

      def validate_plugin_exists!(plugin_name)
        unless exists?(plugin_name)
          raise MetalwareError,
                "Unknown plugin: #{plugin_name}"
        end
      end

      def update_enabled_plugins!(new_enabled_plugins)
        new_cache = cache.merge(enabled: new_enabled_plugins)
        Data.dump(Constants::PLUGINS_CACHE_PATH, new_cache)
      end

      def exists?(plugin_name)
        all_plugin_names.include?(plugin_name)
      end

      def enabled_plugin_names
        cache[:enabled] || []
      end

      def all_plugin_names
        map(&:name)
      end

      def plugin_directories
        plugins_dir.children.select(&:directory?)
      end

      def plugins_dir
        Pathname.new(FilePath.plugins_dir)
      end

      def cache
        Data.load(Constants::PLUGINS_CACHE_PATH)
      end
    end
  end

  Plugin = Struct.new(:path) do
    def name
      path.basename.to_s
    end

    def enabled?
      Plugins.enabled?(name)
    end

    def enabled_identifier
      if enabled?
        '[ENABLED]'.green
      else
        '[DISABLED]'.red
      end
    end

    def enable!
      Plugins.enable!(name)
    end
  end
end
