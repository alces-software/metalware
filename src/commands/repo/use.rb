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
require 'rugged'
require 'fileutils'

require 'constants'

module Metalware
  module Commands
    module Repo
      class Use < CommandHelpers::BaseCommand
        private

        def setup
          @repo_url = args.first
        end

        def run
          if options.force
            FileUtils.rm_rf FilePath.repo
            MetalLog.info 'Force deleted old repo'
          end

          Rugged::Repository.clone_at(@repo_url, FilePath.repo)
          MetalLog.info "Cloned repo from #{@repo_url}"
        rescue Rugged::NetworkError
          raise RuggedCloneError, "Could not find repo: #{@repo_url}"
        rescue Rugged::InvalidError
          raise RuggedCloneError, <<-EOF.squish
            Repository already exists. Use -f to force clone a new one
          EOF
        end
      end
    end
  end
end
