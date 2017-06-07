
require 'base_command'
require 'metal_log'
require 'rugged'

require 'constants'

module Metalware
  module Commands
    module Repo
      class Update < BaseCommand
        def setup(args, options)
          @force = !!options.force
        end

        def run
          repo = Rugged::Repository.init_at(config.repo_path)
          repo.fetch("origin")

          local_commit = repo.branches["master"].target
          remote_commit = repo.branches["origin/master"].target
          ahead_behind = repo.ahead_behind(local_commit, remote_commit)
          uncommited = local_commit.diff_workdir.size

          if @force
            MetalLog.warn
               "Deleted #{ahead_behind[0]} local commit(s)" if ahead_behind[0] > 0
            MetalLog.warn
               "Deleted #{uncommited} local change(s)" if uncommited > 0
          else
            raise LocalAheadOfRemote.new(ahead_behind[0]) if ahead_behind[0] > 0
            raise UncommitedChanges.new(uncommited) if uncommited > 0
          end

          if uncommited + ahead_behind[0] + ahead_behind[1] == 0
            puts "Already up-to-date"
            MetalLog.info "Already up-to-date"
          elsif ahead_behind[0] + ahead_behind[1] + uncommited > 0
            repo.reset(remote_commit, :hard)
            puts "Repo has successfully been updated"
            puts "(Removed local commits/changes)" if ahead_behind[0] + uncommited > 0
            diff = local_commit.diff(remote_commit).stat
            str = "#{diff[0]} file#{ diff[0] == 1 ? '' : 's'} changed, " \
                  "#{diff[1]} insertion#{ diff[1] == 1 ? '' : 's'}(+), " \
                  "#{diff[2]} deletion#{ diff[2] == 1 ? '' : 's'}(-)"
            puts str
            MetalLog.info str
          else
            MetalLog.fatal "Internal error. An impossible condition has been reached!"
            raise "Internal error. Check metal log"
          end
        end
      end

      def requires_repo?
        true
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
    end
  end
end
