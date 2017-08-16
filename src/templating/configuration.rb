
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

require 'node'

# XXX Make `answers` and `raw_config` more similar; basically performing the
# same thing.

# A `Templating::Configuration` represents the configuration used when
# rendering templates for a particular object, which currently can be either a
# node or a primary group of nodes.
module Metalware
  module Templating
    class Configuration
      private_class_method :new

      class << self
        def for_node(node_name, config:)
          groups = Node.new(config, node_name).groups
          new(
            node: node_name,
            groups: groups,
            config: config
          )
        end

        def for_primary_group(group_name, config:)
          new(
            # The only group a primary group should use the configs for is
            # itself.
            groups: [group_name],
            config: config
          )
        end
      end

      attr_reader :node_name, :groups

      def answers
        @answers ||= combine_answers
      end

      # Return the raw merged config for this node/group, without parsing any
      # embedded ERB (this should be done using the `Templater` if needed, as
      # we won't know all the template parameters until a template is being
      # rendered).
      def raw_config
        combine_hashes(configs.map { |c| load_config(c) })
      end

      def load_config(config_name)
        config_path = metalware_config.repo_config_path(config_name)
        Data.load(config_path)
      end

      # The config file names for this node/group, in order of precedence from
      # lowest to highest.
      def configs
        [node_name, *groups, 'domain'].reverse.reject(&:nil?).uniq
      end

      private

      attr_reader :metalware_config

      def initialize(node: nil, groups:, config:)
        @node_name = node
        @groups = groups
        @metalware_config = config
      end

      def combine_answers
        config_answers = configs.map { |c| Data.load(answers_path_for(c)) }
        answer_hashes = [default_answers] + config_answers
        combine_hashes(answer_hashes)
      end

      def answers_path_for(config_name)
        File.join(
          metalware_config.answer_files_path,
          answers_directory_for(config_name),
          "#{config_name}.yaml"
        )
      end

      def answers_directory_for(config_name)
        # XXX Using only the config name to determine the answers directory
        # will potentially lead to answers not being picked up if a group has
        # the same name as a node, or either is 'domain'; we should probably
        # use more information when determining this.
        case config_name
        when 'domain'
          '/'
        when node_name
          'nodes'
        else
          'groups'
        end
      end

      def default_answers
        repo.configure_questions.transform_values do |question|
          question[:default]
        end
      end

      def repo
        @repo ||= Repo.new(metalware_config)
      end

      def combine_hashes(hashes)
        hashes.each_with_object({}) do |config, combined_config|
          raise CombineHashError unless config.is_a? Hash
          combined_config.deep_merge!(config)
        end
      end
    end
  end
end
