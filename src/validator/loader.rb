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

require 'validator/answer'
require 'validator/configure'

module Metalware
  module Validator
    class Loader
      def initialize(metalware_config)
        @load = ValidatorLoadFile.new(metalware_config, self)
        @save = ValidatorSaveFile.new(metalware_config, self)
      end

      private

      attr_reader :load, :save
    end

    class ValidatorFileBase
      def initialize(metalware_config, validator_loader_input)
        @config = metalware_config
        @validator_loader = validator_loader_input
      end

      private

      attr_reader :config, :validator_loader
    end

    class ValidatorLoadFile < ValidatorFileBase
      def configure
        Validator::Configure.new(config.configure_file).load
      end

      def answer(file)
        Validator::Answer.new(config, file, validator_loader).load
      end
    end

    # It might be a wise idea to do all the file loading and saving through the
    # single Validator::Data class. This is included for future expansion.
    # Open to comments
    # I was thinking that the absolute paths could be set in here so only the
    # the relative bit changes
    class ValidatorSaveFile < ValidatorFileBase
    end

    # I was thinking that we could use an explicit file cache, that way if we
    # know we are going to use a file, it can be cached at the start and then
    # the load methods can load the cached file

=begin
    class ValidatorCache < ValidatorFileBase
      def method_missing(s, *a)
        cache_file(s, *a) if validator_data_input.load.responds_to? s
      end
    end
=end
  end
end