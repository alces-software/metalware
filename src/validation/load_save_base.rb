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

require 'file_path'
require 'validation/answer'
require 'validation/configure'
require 'data'

module Metalware
  module Validation
    class LoadSaveBase
      def initialize(*_a)
        raise NotImplementedError
      end

      def domain_answers
        answer(path.domain_answers, :domain)
      end

      def group_answers(name)
        answer(path.group_answers(name), :group)
      end

      def node_answers(name)
        if name == 'local'
          local_answers
        else
          answer(path.node_answers(name), :node)
        end
      end

      def local_answers
        answer(path.local_answers, :local)
      end

      def section_answers(section, name = nil)
        case section
        when :domain
          domain_answers
        when :local
          local_answers
        when :group
          raise InternalError, 'No group name given' if name.nil?
          group_answers(name)
        when :node
          raise InternalError, 'No node name given' if name.nil?
          node_answers(name)
        else
          raise InternalError, "Unrecognised question section: #{section}"
        end
      end

      private

      attr_reader :path, :config

      def answer(_absolute_path, _section)
        raise NotImplementedError
      end
    end
  end
end
