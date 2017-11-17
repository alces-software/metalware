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

module Metalware
  module Commands
    class Sync < CommandHelpers::BaseCommand
      private

      attr_reader :manifest

      def setup
        @manifest = loader.staging_manifest
      end

      def run
        move_build_files_into_place
      ensure
        Data.dump(file_path.staging_manifest, manifest)
      end

      def move_build_files_into_place
        manifest[:files].delete_if do |data|
          begin
            data[:managed] ? move_managed(data) : move_non_managed(data)
            true
          rescue => e
            MetalLog.warn "Failed to sync: #{data[:staging]}"
            MetalLog.warn e.inspect
            return false
          end
        end
      end

      def move_non_managed(data)
        FileUtils.mv(data[:staging], data[:sync])
      end

      def move_managed(data)
        raise NotImplementedError
      end
    end
  end
end
