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
require 'alces/stack/repo'
require 'alces/stack/log'
require 'alces/tools/execution'
require 'rugged'

module Alces
  module Stack
    module Repo
      class Run
        include Alces::Tools::Execution

        def initialize(options = {})
          @opt = Options.new(options)
        end

        class Options
          def initialize(options = {})
            @options = options
          end

          def get_repo_path(cmd)
            file = send(cmd)
            path = "/var/lib/metalware/repos/#{file}".chomp.gsub(/\/\/+/,"/")
          end

          def get_command
            cmds = [:import, :list, :update]
            cmd = nil
            cmds.each do |c|
              cmd_bool = send("#{c}?".to_sym)
              if cmd_bool && !!cmd
                raise ErrorMultipleCommands.new(cmd, c)
              elsif cmd_bool
                cmd = c
              end
            end
            if cmd.nil?
              Alces::Stack::Repo::CLI.usage
              Kernel.exit
            end
            cmd
          end

          class ErrorMultipleCommands < StandardError
            def initialize(arg1, arg2)
              msg = "Can not run command with: --#{arg1} and --#{arg2}"
              super msg
            end
          end

          def method_missing(s, *a, &b)
            if @options.key?(s)
              @options[s]
            elsif s[-1] == "?"
              !!@options[s[0...-1].to_sym]
            else
              super
            end
          end       
        end

        def run!
          send(@opt.get_command)
        rescue NoMethodError => e
          raise $!, "'metal repo --#{@opt.get_command}' not found"
        end

        def import
          raise ErrorURLNotFound.new unless @opt.url?
          puts @opt.url
          Rugged::Repository.clone_at(@opt.url, @opt.get_repo_path(:import))
        end

        class ErrorURLNotFound < StandardError
          def initialize(msg = "Remote repository URL not specified")
            super
          end
        end
      end
    end
  end
end
