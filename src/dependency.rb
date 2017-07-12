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
require 'constants'
require 'validator/configure'

module Metalware
  class Dependency
    def initialize(metal_config, command_input, dependency_hash = {})
      @config = metal_config
      @dependency_hash = dependency_hash
      @command = command_input
    end

    def enforce
      @dependency_hash.each { |dep, values|
        unless values.is_a?(Array)
          msg = "Dependency values must be an array, check: #{dep}"
          raise DependencyInternalError, msg
        end
        send(:"validate_#{dep}")
        values.each { |value| validate_dependency_value(dep, value) }
      }
    end

    private

    attr_reader :config, :command

    def validate_dependency_value(dep, value)
      unless valid_file?(dep, value)
        raise DependencyFailure, get_value_failure_message(dep, value)
      end
    end

    def validate_repo
      @validated_repo ||= begin
        msg = "'#{command}' requires a repo. Please run 'metal repo use'"
        raise DependencyFailure, msg unless valid_file?(:repo, '.git', true)
        true # Sets the @validate_repo value so it only runs once
      end
    end

    def validate_configure
      @validate_configure ||= begin
        validate_repo
        valid_configure_yaml = valid_file?(:repo, "configure.yaml") { |path|
          Validator::Configure.new(path).validate.success?
        }
        unless valid_configure_yaml
          msg = "'#{command}' requires a valid 'repo/configure.yaml' file"
          raise(DependencyFailure, msg)
        end
        unless valid_file?(:configure , "", true)
          msg = "Could not locate answer files: #{config.answer_files_path}"
          raise DependencyFailure, msg
        end
        true # Sets the @validate_configure value so it only runs once
      end
    end

    def valid_file?(dep, value, validate_directory = false, &block)
      path = begin
        case dep
        when :repo
          File.join(config.repo_path, value)
        when :configure
          File.join(config.answer_files_path, value)
        else
          msg = "Could not generate file path for dependency #{dep}"
          raise DependencyInternalError, msg
        end
      end

      if validate_directory
        Dir.exists?(path)
      elsif File.file?(path)
        block.nil? ? true : !!(yield path)
      else
        false
      end
    end

    def get_value_failure_message(dep, value)
      msg = "The '#{dep}' dependency (value: #{value}) has failed"
      case dep
      when :repo
        msg = "Could not find repo file: #{value}"
      when :configure
        cmd = File.basename(value, ".yaml")
        cmd = "group #{cmd}" unless cmd == "domain"
        msg = "Could not locate required answer file: #{value}. Please run " \
              "'metal configure #{cmd}'"
      end
      msg
    end
  end
end