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

require 'system_command'
require 'metal_log'
require 'file_path'

module Metalware
  module Commands
    class Edit < CommandHelpers::BaseCommand
      private

      attr_reader :relative_file_path

      def setup
        @relative_file_path = args[0]
      end

      def run
        cmd = "#{editor} #{file}"
        MetalLog.info("exec: #{cmd}")
        exec(cmd)
      end

      def editor
        if system_visual
          system_visual
        elsif system_editor
          system_editor
        else
          'vi'
        end
      end

      def system_visual
        ENV['VISUAL']
      end

      def system_editor
        ENV['EDITOR']
      end

      def file
        File.join(file_path.metalware_data, 'rendered', relative_file_path)
      end

      def file_path
        @file_path ||= FilePath
      end
    end
  end
end
