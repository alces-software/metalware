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

require 'constants'
require 'config'

module Metalware
  class FilePath
    def initialize(metalware_config)
      @config = metalware_config
    end

    def configure_file
      config.configure_file
    end

    def domain_answers
      config.domain_answers_file
    end

    def group_answers(group)
      config.group_answers_file(group)
    end

    def node_answers(node)
      config.node_answers_file(node)
    end

    # Allows the constant paths to be queried easily
    def method_missing(path_name, *_a, &_b)
      if valid_constant?(path_name)
        Constants.const_get(:"#{constant_name(path_name)}")
      else
        super
      end
    end

    def respond_to_missing?(path_name, *_a)
      valid_constant?(path_name) || super
    end

    private

    def constant_name(path_name)
      "#{path_name.upcase}_PATH"
    end

    def valid_constant?(path_name)
      Constants.const_defined?(constant_name(path_name))
    end

    attr_reader :config
  end
end
