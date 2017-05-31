
require 'commands/base_command'
require 'rugged'
require 'fileutils'

require 'constants'

module Metalware
  module Commands
    module Repo
      class Use < BaseCommand
        def setup(args, options)
          @repo_url = args.first
          @options = options
        end

        def run
          if @options.force
            FileUtils::rm_rf Constants::REPO_PATH
            MetalLog.info "Force deleted old repo"
          end

          Rugged::Repository.clone_at(@repo_url, Constants::REPO_PATH)
          MetalLog.info "Cloned repo from #{@options.url}"
        rescue Rugged::InvalidError
          raise $!, "Repository already exists. Use -f to force clone a new one"
        end
      end
    end
  end
end
