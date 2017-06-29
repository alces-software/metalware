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

require 'base_command'
require 'constants'
require 'nodes'
require 'templater'

module Metalware
  module Commands
    class Hosts < BaseCommand
      HOSTS_FILE = '/etc/hosts'

      private

      def setup(args, options)
        @options = options

        node_identifier = args.first
        @nodes = Nodes.create(config, node_identifier, options.group)
      end

      def run
        add_nodes_to_hosts
      end

      def requires_repo?
        true
      end

      def add_nodes_to_hosts
        @nodes.template_each do |parameters|
          if @options.dry_run
            Templater.render_to_stdout(config, template_path, parameters)
          else
            Templater.render_and_append_to_file(config, template_path, HOSTS_FILE, parameters)
          end
        end
      end

      def template_path
        File.join(config.repo_path, 'hosts', @options.template)
      end
    end
  end
end
