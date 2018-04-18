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

require 'plugins/configure_questions_builder'
require 'plugins/plugin'

module Metalware
  module Plugins
    class << self
      def all
        plugin_directories.map do |dir|
          Plugin.new(dir)
        end
      end

      def activated
        all.select(&:activated?)
      end

      def activated?(plugin_name)
        !deactivated_plugin_names.include?(plugin_name)
      end

      def activate!(plugin_name)
        validate_plugin_exists!(plugin_name)
        return if activated?(plugin_name)

        new_deactivated_plugins = deactivated_plugin_names.reject do |name|
          name == plugin_name
        end
        update_deactivated_plugins!(new_deactivated_plugins)
      end

      def deactivate!(plugin_name)
        validate_plugin_exists!(plugin_name)

        new_deactivated_plugins = deactivated_plugin_names + [plugin_name]
        update_deactivated_plugins!(new_deactivated_plugins)
      end

      def enabled_question_identifier(plugin_name)
        [
          Constants::CONFIGURE_INTERNAL_QUESTION_PREFIX,
          'plugin_enabled',
          plugin_name,
        ].join('--')
      end

      private

      def validate_plugin_exists!(plugin_name)
        return if exists?(plugin_name)
        raise MetalwareError, "Unknown plugin: #{plugin_name}"
      end

      def update_deactivated_plugins!(new_deactivated_plugins)
        new_cache = cache.merge(deactivated: new_deactivated_plugins)
        Data.dump(Constants::PLUGINS_CACHE_PATH, new_cache)
      end

      def exists?(plugin_name)
        all_plugin_names.include?(plugin_name)
      end

      def deactivated_plugin_names
        cache[:deactivated] || []
      end

      def all_plugin_names
        all.map(&:name)
      end

      def plugin_directories
        return [] unless plugins_dir.exist?
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
end
