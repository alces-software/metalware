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

require 'exceptions'
require 'file_path'
require 'validation/answer'
require 'data'

module Metalware
  module Validation
    class Saver
      def initialize(metalware_config)
        @config = metalware_config
      end

      def respond_to_missing?(s, *_a)
        Methods.instance_methods.include?(s)
      end

      # Enforces the first argument to always be the data
      def method_missing(s, *a, &b)
        data = a[0]
        if respond_to_missing?(s)
          raise SaverNoData unless data
          Methods.new(config, data).send(s, *a[1..-1], &b)
        else
          super
        end
      end

      private

      attr_reader :config

      def method_builder(data)
        Methods.new(config, data)
      end

      class Methods
        def initialize(config, data)
          @config = config
          @path = FilePath.new(config)
          @data = data
        end

        def domain_answers; end

        private

        attr_reader :path, :config, :data
      end
    end
  end
end
