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
  # MetalwareError is the base error class to distinguish the custom errors
  # from the built ins/ other libraries. The UserMetalwareError is a subset
  # of the errors that result from a user action (as opposed to metalware
  # failing). The user errors suppress the `--trace` prompt, which should
  # make it clearer that it isn't an internal metalware error.
  class MetalwareError < StandardError; end
  class UserMetalwareError < MetalwareError; end

  class StrictWarningError < UserMetalwareError; end
  class InvalidInput < UserMetalwareError; end
  class InvalidConfigParameter < UserMetalwareError; end
  class InvalidLocalBuild < UserMetalwareError; end

  class UnexpectedError < MetalwareError
    def initialize(msg = 'An unexpected error has occurred')
      super
    end
  end

  class StatusDataIncomplete < MetalwareError
    def initialize(msg = 'Failed to receive data for all nodes')
      super
    end
  end

  class ValidationFailure < UserMetalwareError; end

  class RuggedError < UserMetalwareError; end
  class RuggedCloneError < RuggedError; end

  class LocalAheadOfRemote < RuggedError
    def initialize(num)
      msg = "The local repo is #{num} commits ahead of remote. -f will " \
        'override local commits'
      super msg
    end
  end

  class UncommitedChanges < RuggedError
    def initialize(num)
      msg = "The local repo has #{num} uncommitted changes. -f will " \
        'delete these changes. (untracked unaffected)'
      super msg
    end
  end

  # Alias for Exception to use to indicate we want to catch everything, and to
  # also tell Rubocop to be quiet about this.
  IntentionallyCatchAnyException = Exception
end
