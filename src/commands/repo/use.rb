
require 'base_command'
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
            FileUtils::rm_rf config.repo_path
            MetalLog.info "Force deleted old repo"
          end

          Rugged::Repository.clone_at(@repo_url, config.repo_path)
          MetalLog.info "Cloned repo from #{@repo_url}"
        rescue Rugged::InvalidError
          raise $!, "Repository already exists. Use -f to force clone a new one"
        end
      end
    end
  end
end
