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
require 'data'
require 'constants'

module Metalware
  module Validator
    class Loader
      def initialize(metalware_config)
        @load = ValidatorLoadFile.new(metalware_config, self)
        @save = ValidatorSaveFile.new(metalware_config, self)
      end

      attr_reader :load

      def save(data)
        ValidatorSaveHelper.new(@save, data)
      end
    end

    # Contains the code for finding the paths to each file type
    class ValidatorFileBase
      def initialize(metalware_config, validator_loader_input)
        @config = metalware_config
        @validator_loader = validator_loader_input
      end

      private

      def find_path(key, *arguments)
        PATH_PROCS[key].call(*arguments)
      end

      PATH_PROCS = {
        group_cache: proc { Constants::GROUPS_CACHE_PATH },
        configure_file: proc { config.configure_file },
        domain_answers: proc { config.domain_answers_file },
        group_answers: proc { |group| config.group_answers_file(group) },
        node_answers: proc { |node| config.node_answers_file(node) },
      }.freeze

      attr_reader :config, :validator_loader
    end

    # Loads and validates the file
    class ValidatorLoadFile < ValidatorFileBase
      def configure
        Validator::Configure.new(find_path(:configure_file)).load
      end

      def group_cache
        Data.load(find_path(:group_cache))
      end

      def domian_answers
        answer(find_path(:domain_answers), :domain)
      end

      def group_answers(file)
        answer(find_path(:group_answers, file), :groups)
      end

      def node_answers(file)
        answer(find_path(:node_answers, file), :nodes)
      end

      private

      def answer(absolute_path, section)
        validator = Validator::Answer.new(config,
                                          absolute_path,
                                          loader: validator_loader,
                                          input_section: section)
        validator.load
      end
    end

    # Saves data to a file
    # The first input to all methods must be 'data'
    class ValidatorSaveFile < ValidatorFileBase
      def group_cache(data)
        Data.dump(find_path(:group_cache), data)
      end
    end

    # Used to change the save syntax to:
    # file_loader.save(data_to_be_saved).<file_saving_method>
    class ValidatorSaveHelper
      def initialize(validator_save_file, data)
        @data = data
        @validator_save_file = validator_save_file
      end

      def valid_method?(method)
        @validator_save_file.respond_to?(method)
      end

      def respond_to_missing?(s, *_a)
        valid_method?(s) || super
      end

      def method_missing(s, *a, &_b)
        valid_method?(s) ? @validator_save_file.send(s, @data, *a) : super
      end
    end

    # I was thinking that we could use an explicit file cache, that way if we
    # know we are going to use a file, it can be cached at the start and then
    # the load methods can load the cached file

    #     class ValidatorCache < ValidatorFileBase
    #       def method_missing(s, *a)
    #         cache_file(s, *a) if validator_data_input.load.responds_to? s
    #       end
    #     end
  end
end
