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
require 'fileutils'

module Alces
  module Stack
    module Repo
      class Run
        include Alces::Tools::Execution

        def initialize(options = {})
          @opt = Options.new(options)
        end

        class Options
          CMDS = { clone_repo: "clone",
                   list: "list", 
                   update: "update" }

          def initialize(options = {})
            @options = options
          end

          def get_repo_path(repo = name_input)
            path = "/var/lib/metalware/repos/#{repo}".chomp.gsub(/\/\/+/,"/")
          end

          def name_input
            raise NoNameGiven unless !!@options[:name_input]
            @options[:name_input]
          end

          def get_command
            cmd = nil
            CMDS.each do |key, value|
              cmd_bool = send("#{key}?".to_sym)
              if cmd_bool && !!cmd
                raise ErrorMultipleCommands.new(CMDS[cmd], value)
              elsif cmd_bool
                cmd = key
              end
            end
            if cmd.nil?
              Alces::Stack::Repo::CLI.usage
              Kernel.exit
            end
            cmd
          end

          def get_command_cli; CMDS[get_command]; end

          def method_missing(s, *a, &b)
            if @options.key?(s)
              @options[s]
            elsif s[-1] == "?"
              !!@options[s[0...-1].to_sym]
            else
              super
            end
          end

          class NoNameGiven < StandardError
            def initialize(msg = "--name is required"); super; end
          end

          class ErrorMultipleCommands < StandardError
            def initialize(arg1, arg2)
              msg = "Can not run command with: --#{arg1} and --#{arg2}"
              super msg
            end
          end
        end

        def run!
          send(@opt.get_command)
        rescue Rugged::NetworkError => e
          raise $!, "Could not locate remote repository or requires authentication"
        end

        def method_missing(s, *a, &b)
          raise NoMethodError, "'metal repo --#{@opt.get_command_cli}' not available"
        end

        def list
          repos = Dir.entries("/var/lib/metalware/repos")
          repos.delete(".")
          repos.delete("..")
          @list_good_repos = {}
          @list_check_repos = {}
          @list_bad_repos = {}

          repos.each do |repo_name|
            begin
              repo = Rugged::Repository.init_at("/var/lib/metalware/repos/#{repo_name}")
              repo.head
              remote = repo.remotes["origin"]
              raise NoRemote if remote.nil?
              raise ErrorFetch unless remote.check_connection(:fetch)
              @list_good_repos[repo_name] = remote.url
            rescue Rugged::ReferenceError => e
              Alces::Stack::Log.error "#<#{e.class}: Could not find HEAD " \
                                      "commit for repo: '#{repo_name}'>"
              @list_bad_repos[repo_name] = "HEAD commit missing"
            rescue NoRemote => e
              Alces::Stack::Log.error "#<#{e.class}: No remote repo has been " \
                                      "set for repo: '#{repo_name}'>"
              @list_bad_repos[repo_name] = "No remote repo set"
            rescue ErrorFetch => e
              Alces::Stack::Log.error "#<#{e.class}: Could not fetch repo: " \
                                      "'#{repo_name}, url: #{remote.url}'>"
              @list_check_repos[repo_name] = remote.url
            end
          end

          hash_descriptions = {
            list_good_repos: "Repos:",
            list_check_repos: "Could not 'git fetch' from repos. Check URL and " \
                              "internet connection",
            list_bad_repos: "An error occurred in the following repos:"
          }

          @max_repo_length = 0
          hash_descriptions.each do |hash, notUsed|
            instance_variable_get("@#{hash}").each do |key, notUsed| 
              @max_repo_length = key.length if @max_repo_length < key.length
            end
          end

          puts_results = lambda { |hash_name, msg|
            repo_hash = instance_variable_get("@#{hash_name}")
            unless repo_hash.empty?
              puts if @puts_space_list
              puts msg
              repo_hash.each do |key, value|
                padding = " " * (@max_repo_length - key.length) 
                puts "#{key}#{padding} : #{value}"
              end
              @puts_space_list = true
            end
          }
          @puts_space_list = false
          hash_descriptions.each { |key, value| puts_results.call(key, value) }
        end

        def clone_repo
          raise ErrorURLNotFound.new unless @opt.url?
          if @opt.force?
            FileUtils::rm_rf @opt.get_repo_path
            Alces::Stack::Log.info "Force deleted old repo"
          end
          Rugged::Repository.clone_at(@opt.url, @opt.get_repo_path)
          Alces::Stack::Log.info "Cloned '#{@opt.name_input}' from #{@opt.url}"
        rescue Rugged::InvalidError => e
          raise $!, "Repository already exists. -f to force clone a new one"
        end

        def update
          raise RepoNotFound.new(@opt.name_input) unless File.directory?(@opt.get_repo_path)
          repo = Rugged::Repository.init_at(@opt.get_repo_path)
          repo.fetch("origin")

          local_commit = repo.branches["master"].target
          remote_commit = repo.branches["origin/master"].target
          ahead_behind = repo.ahead_behind(local_commit, remote_commit)
          uncommited = local_commit.diff_workdir.size

          if @opt.force?
            Alces::Stack::Log.warn
              "Deleted #{ahead_behind[0]} local commit(s)" if ahead_behind[0] > 0
            Alces::Stack::Log.warn 
              "Deleted #{uncommited} local change(s)" if uncommited > 0
          else
            raise LocalAheadOfRemote.new(ahead_behind[0]) if ahead_behind[0] > 0
            raise UncommitedChanges.new(uncommited) if uncommited > 0
          end

          if uncommited + ahead_behind[0] + ahead_behind[1] == 0
            puts "Already up-to-date"
            Alces::Stack::Log.info "Already up-to-date"
          elsif ahead_behind[0] + ahead_behind[1] + uncommited > 0
            repo.reset(remote_commit, :hard)
            puts "Repo has successfully been updated" 
            puts "(Removed local commits/ changes)" if ahead_behind[0] + uncommited > 0
            diff = local_commit.diff(remote_commit).stat
            str = "#{diff[0]} file#{ diff[0] == 1 ? '' : 's'} changed, " \
                  "#{diff[1]} insertion#{ diff[1] == 1 ? '' : 's'}(+), " \
                  "#{diff[2]} deletion#{ diff[2] == 1 ? '' : 's'}(-)"
            puts str
            Alces::Stack::Log.info str
          else
            Alces::Stack::Log.fatal "Internal error. An impossible condition has " \
                                    "been reached!"
            raise "Internal error. Check metal log"
          end
        end

        class NoRemote < StandardError; end
        class ErrorFetch < StandardError; end

        class RepoNotFound < StandardError
          def initialize(repo)
            msg = "Could not find repo matching: #{repo}"
            super msg
          end
        end

        class LocalAheadOfRemote < StandardError
          def initialize(num)
            msg = "The local repo is #{num} commits ahead of remote. -f will " \
                  "override local commits"
            super msg; 
          end
        end

        class UncommitedChanges < StandardError
          def initialize(num) 
            msg = "The local repo has #{num} uncommitted changes. -f will " \
                  "delete these changes. (untracked unaffected)"
            super msg; 
          end
        end

        class ErrorURLNotFound < StandardError
          def initialize(msg = "Remote repository URL not specified"); super; end
        end
      end
    end
  end
end
