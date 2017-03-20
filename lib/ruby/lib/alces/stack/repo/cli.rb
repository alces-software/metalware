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
require 'alces/tools/cli'
require 'alces/stack'
require 'alces/stack/log'

module Alces
  module Stack
    module Repo
      class CLI
        include Alces::Tools::CLI

        root_only
        name 'metal repo'
        description "Manage repositories from git"
        
        option  :repo_name,
                "Name of the repo directory: /var/lib/metalware/repos/<name>",
                "-n", "--name",
                default: false

        option  :import,
                "URL to clone a git repository from",
                "-i", "--import",
                default: false

        flag    :list,
                "TBA",
                "-l", "--list",
                default: false

        flag    :update,
                "TBA",
                "-u", "--update",
                default: false

        flag    :force,
                "Force the command to take place",
                "-f", "--force"

        def assert_preconditions!
          Alces::Stack::Log.progname = "repo"
          Alces::Stack::Log.info "metal repo #{ARGV.to_s.gsub(/[\[\],\"]/, "")}"
          self.class.assert_preconditions!
        end

        def execute
          Alces::Stack::Boot.run!(
              repo_name: repo_name,
              import: import,
              list: list,
              update: update,
              force: force
            )
        rescue => e
          Alces::Stack::Log.fatal e.inspect
          raise e
        end
      end
    end
  end
end