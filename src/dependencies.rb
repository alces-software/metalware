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

module Metalware
  class Dependencies
    def initialize(metal_config, command_input, dep_hash = {})
      @config = metal_config
      @dep_hash = dep_hash
      @command = command_input
    end

    def enforce
      @dep_hash.each { |dep, values|
        next unless values # Rejects nil and false
        values = [values] unless values.is_a?(Array)
        values.each { |value| validate_dependency(dep, value) }
      }
    end

    private

    attr_reader :config, :command

    def validate_dependency(dep, value)
      send(:"validate_#{dep}")
      return if value.is_a?(TrueClass)
      path = generate_file_path(dep, value)
      unless path_exists?(path)
        raise DependencyFailure, get_generic_failure_message(dep, value)
      end
    end

    def validate_repo
      @validated_repo ||= begin
        msg = "'#{command}' requires a repo. Please run 'metal repo use'"
        path = generate_file_path(:repo, "")
        raise DependencyFailure, msg unless path_exists?(path, true)
        true
      end
    end

    def generate_file_path(dep, value)
      case dep
      when :repo
        File.join(@config.repo_path, value)
      else
        msg = "Could not generate file path for dependency #{dep}"
        raise DependencyInternalError, msg
      end
    end

    def path_exists?(path, validate_directory = false)
      if validate_directory
        Dir.exists?(path)
      else
        File.file?(path)
      end
    end

    def get_generic_failure_message(dep, value)
      msg = "The '#{dep}' dependency (value: #{value}) has failed"
      case dep
      when :repo
        msg = "Could not find repo file: #{value}"
      end
      msg
    end
  end
end