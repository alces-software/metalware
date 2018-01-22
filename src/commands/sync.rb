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
require 'staging'

module Metalware
  module Commands
    class Sync < CommandHelpers::BaseCommand
      private

      attr_reader :manifest

      def run
        Staging.update do |staging|
          sync_files(staging)
          staging.save
          restart_services(staging)
          clean_up_staging_directory
        end
      end

      def sync_files(staging)
        staging.delete_file_if do |file|
          validate(file)
          FileUtils.mkdir_p File.dirname(file.sync)
          staging.push_service(file.service) if file.service
          File.write(file.sync, file.content)
        end
      end

      def validate(data)
        return unless data.validator
        error = nil
        begin
          return if data.validator.constantize.validate(data.content)
        rescue StandardError => e
          error = e
        end
        msg = 'A file failed to be validated'
        msg += "\nSync Path: #{data.sync}"
        msg += "\nValidator: #{data.validator}"
        msg += "\nManaged: #{data.managed}"
        msg += "\nError: #{error.inspect}" if error
        raise ValidationFailure, msg
      end

      def restart_services(staging)
        staging.delete_service_if do |service|
          service.constantize.restart_service
        end
      end

      def clean_up_staging_directory
        Dir[File.join(FilePath.staging_dir, '**/*')]
          .select { |d| File.directory?(d) }
          .reverse
          .each { |d| Dir.rmdir d if Dir[File.join(d, '**/*')].length.zero? }
      end
    end
  end
end
