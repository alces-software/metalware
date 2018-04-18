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

require 'command_helpers/base_command'
require 'metal_log'
require 'rugged'
require 'exceptions'

require 'constants'

module Metalware
  module Commands
    module Repo
      class Update < CommandHelpers::BaseCommand
        private

        def setup
          @force = !!options.force
        end

        def run
          repo = Rugged::Repository.init_at(FilePath.repo)
          repo.fetch('origin')

          local_commit = repo.branches['master'].target
          remote_commit = repo.branches['origin/master'].target
          ahead_behind = repo.ahead_behind(local_commit, remote_commit)
          uncommited = local_commit.diff_workdir.size

          if @force
            if ahead_behind[0] > 0
              MetalLog.warn "Deleted #{ahead_behind[0]} local commit(s)"
            end
            if uncommited > 0
              MetalLog.warn "Deleted #{uncommited} local change(s)"
            end
          else
            raise LocalAheadOfRemote, ahead_behind[0] if ahead_behind[0] > 0
            raise UncommitedChanges, uncommited if uncommited > 0
          end

          if uncommited + ahead_behind[0] + ahead_behind[1] == 0
            puts 'Already up-to-date'
            MetalLog.info 'Already up-to-date'
          elsif ahead_behind[0] + ahead_behind[1] + uncommited > 0
            repo.reset(remote_commit, :hard)
            puts 'Repo has successfully been updated'
            if ahead_behind[0] + uncommited > 0
              puts '(Removed local commits/changes)'
            end
            diff = local_commit.diff(remote_commit).stat
            str = "#{diff[0]} file#{diff[0] == 1 ? '' : 's'} changed, " \
                  "#{diff[1]} insertion#{diff[1] == 1 ? '' : 's'}(+), " \
                  "#{diff[2]} deletion#{diff[2] == 1 ? '' : 's'}(-)"
            puts str
            MetalLog.info str
          else
            raise UnexpectedError
          end
        end

        def dependency_hash
          {
            repo: [],
          }
        end
      end
    end
  end
end
