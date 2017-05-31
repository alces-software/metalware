
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
          @force = options.force
        end

        def run
          if @force
            FileUtils::rm_rf Constants::REPO_PATH
            MetalLog.info "Force deleted old repo"
          end

          Rugged::Repository.clone_at(@repo_url, Constants::REPO_PATH)
          MetalLog.info "Cloned '#{@opt.name_input}' from #{@opt.url}"
        rescue Rugged::InvalidError
          raise $!, "Repository already exists. Use -f to force clone a new one"
        end
      end
    end
  end
end
