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
      def all
        plugin_directories.map do |dir|
          Plugin.new(dir)
        end
      end

      def enabled
        all.select(&:enabled?)
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

    def configure_questions
      ConfigureQuestionsBuilder.build(self)
    end
  end

  ConfigureQuestionsBuilder = Struct.new(:plugin) do
    private_class_method :new

    def self.build(plugin)
      new(plugin).build
    end

    def build
      Constants::CONFIGURE_SECTIONS.map do |section|
        [section, question_tree_for_section(section)]
      end.to_h
    end

    private

    def question_tree_for_section(section)
      {
        identifier: "metalware_internal--plugin_enabled--#{plugin.name}",
        question: "Should '#{plugin.name}' plugin be enabled for #{section}?",
        type: 'boolean',
        dependent: questions_for_section(section),
      }
    end

    def questions_for_section(section)
      configure_data[section].map { |q| namespace_question_tree(q) }
    end

    def configure_data
      @configure_data ||= default_configure_data.merge(
        Data.load(configure_file_path)
      )
    end

    def default_configure_data
      Constants::CONFIGURE_SECTIONS.map do |section|
        [section, []]
      end.to_h
    end

    def configure_file_path
      File.join(plugin.path, 'configure.yaml')
    end

    def namespace_question_tree(question_hash)
      # Prepend plugin name to question text, as well as recursively to all
      # dependent questions, so source of plugin questions is clear when
      # configuring.
      question_hash.map do |k, v|
        new_value = case k
                    when :question
                      "#{plugin_identifier} #{v}"
                    when :dependent
                      v.map { |q| namespace_question_tree(q) }
                    else
                      v
                    end
        [k, new_value]
      end.to_h
    end

    def plugin_identifier
      "[#{plugin.name}]"
    end
  end
end
