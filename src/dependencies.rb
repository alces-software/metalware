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
      @dep_hash.each { |dep, value| run_dependency(dep, value) if value }
    end

    private

    attr_reader :config, :command

    def run_dependency(dep, value)
      case dep
      when :repo
        check_repo_dependency(value)
      else
        msg = "Unknown dependency: #{dep}"
        raise DependencyInternalError, msg
      end
    end

    def check_repo_dependency(dirs_input)
      dirs = case dirs_input
      when TrueClass # Only check if the repo exists if the value is true
        [""]
      when Array
        dirs_input.unshift("")
      when String
        ["", dirs_input]
      else
        msg = "Unrecognized repo dependency value: #{dirs_input}"
        raise DependencyInternalError, msg
      end
      dirs.each do |dir|
        path = File.join(config.repo_path, dir)
        if dir == ""
          msg = "'#{command}' requires a repo; please run 'metal repo use'"
          if !File.directory?(path)
            raise DependencyFailure, msg
          elsif Dir[File.join(path, "*")].empty?
            raise DependencyFailure, msg
          end
        elsif !File.directory?(path)
          msg = "Repo found but missing '#{dir}' directory, please check the " \
                "repo and try again"
          raise DependencyFailure, msg
        end
      end
    end
  end
end