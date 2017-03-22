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
        
        option  :name_input,
                "Name of the repository in file structure",
                "-n", "--name",
                default: false
        
        option  :url,
                "URL to remote repository",
                "-r", "--url",
                default: false

        flag    :clone_repo,
                "Name of repository to clone. Requires a URL",
                "-c", "--clone",
                default: false

        flag    :list,
                "TBA",
                "-l", "--list",
                default: false

        flag    :update,
                "Updates the local repository to match remote",
                "-u", "--update",
                default: false

        flag    :force,
                "Force the command to take place. May delete existing directories",
                "-f", "--force"

        def assert_preconditions!
          Alces::Stack::Log.progname = "repo"
          Alces::Stack::Log.info "metal repo #{ARGV.to_s.gsub(/[\[\],\"]/, "")}"
          self.class.assert_preconditions!
        end

        def execute
          Alces::Stack::Repo.run!(
              name_input: name_input,
              clone_repo: clone_repo,
              list: list,
              update: update,
              force: force,
              url: url
            )
        rescue => e
          Alces::Stack::Log.fatal e.inspect
          raise e
        end
      end
    end
  end
end