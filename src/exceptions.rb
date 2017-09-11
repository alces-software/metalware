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
  class MetalwareError < StandardError
  end

  class UnsetConfigLogError < MetalwareError
    def initialize(msg = 'Error in MetalLog. Config not set')
      super
    end
  end

  class NoGenderGroupError < MetalwareError
  end

  class NodeNotInGendersError < MetalwareError
  end

  class SystemCommandError < MetalwareError
  end

  class StrictWarningError < MetalwareError
  end

  class NoRepoError < MetalwareError
  end

  class RecursiveConfigDepthExceededError < MetalwareError
    def initialize(msg = 'Input hash may contain infinitely recursive ERB')
      super
    end
  end

  class UnsetParameterAccessError < MetalwareError
  end

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

  class InvalidInput < MetalwareError
  end

  class InvalidConfigParameter < MetalwareError
  end

  class IterableRecursiveOpenStructPropertyError < MetalwareError
  end

  class CombineHashError < MetalwareError
    def initialize(msg = 'Could not combine config or answer hashes')
      super
    end
  end

  class UnknownQuestionTypeError < MetalwareError
  end

  class UnknownDataTypeError < MetalwareError
  end

  class LoopErbError < MetalwareError
    def initialize(msg = 'Input hash may contain infinitely recursive ERB')
      super
    end
  end

  class MissingParameterError < MetalwareError
  end

  class ValidationInternalError < MetalwareError
  end

  class ValidationFailure < MetalwareError
  end

  # XXXX, we need think about the future of the DependencyFailure,
  # It maybe completely replaced with Validation::Loader and a file cache.
  # If this is the case Dependency Failure/ InternalError will be replaced
  # with Validation Failure/ InternalError

  # Use this error as the general catch all in Dependencies
  # The dependency can't be checked as the logic doesn't make sense
  # NOTE: We should try and prevent these errors from appearing in production
  class DependencyInternalError < MetalwareError
  end

  # Use this error when the dependency is checked but isn't met
  # NOTE: This is the only dependency error we see in production
  class DependencyFailure < MetalwareError
  end

  # Error to be used when a file that should exist doesn't.
  class FileDoesNotExistError < MetalwareError
  end

  # Error to be raised by Data class when invalid data loaded/attempted to be
  # dumped.
  class DataError < MetalwareError
  end

  class RuggedError < MetalwareError
  end

  class RuggedCloneError < RuggedError
  end

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

  class DomainTemplatesInternalError < MetalwareError
  end

  class EditModeError < MetalwareError
  end

  class MissingExternalDNS < MetalwareError
  end

  class SaverNoData < MetalwareError
    def initialize(msg = 'No data provided to Validation::Saver'); end
  end

  class MissingExternalDNS < MetalwareError
  end

  class SelfBuildMethodError < MetalwareError
    def initialize(build_method: nil, building_self_node: true)
      msg = if build_method
              "The '#{build_method}' build method can not be used for the self " \
              "node. The self node can only be built with the 'self' build method"
            elsif building_self_node
              'The self build method has had an unexpected error'
            else
              "The self build method can not be used for non 'self' nodes"
            end
      super(msg)
    end
  end

  class InternalError < MetalwareError
  end
end

# Alias for Exception to use to indicate we want to catch everything, and to
# also tell Rubocop to be quiet about this.
IntentionallyCatchAnyException = Exception

class AbortInTestError < StandardError
end
