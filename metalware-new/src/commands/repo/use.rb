
require 'rugged'
require 'fileutils'

require 'constants'

module Metalware
  module Commands
    module Repo
      class Use
	def initialize(args, options)
	  repo_url = args.first

          if options.force
            FileUtils::rm_rf Constants::REPO_PATH
            # Alces::Stack::Log.info "Force deleted old repo"
          end
          Rugged::Repository.clone_at(repo_url, Constants::REPO_PATH)
          # Alces::Stack::Log.info "Cloned '#{@opt.name_input}' from #{@opt.url}"
        rescue Rugged::InvalidError
	  raise $!, "Repository already exists. Use -f to force clone a new one"
	end
      end
    end
  end
end
