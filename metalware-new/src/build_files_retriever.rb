
require 'uri'
require 'open-uri'

require 'constants'
require 'input'


module Metalware
  class BuildFilesRetriever
    attr_reader :node_name, :config

    def initialize(node_name, config)
      @node_name = node_name
      @config = config
    end

    def retrieve(file_namespaces)
      file_namespaces.map do |namespace, identifiers|
        [
          namespace,
          identifiers.map { |identifier| file_hash_for(namespace, identifier) }
        ]
      end.to_h
    end

    private

    def file_hash_for(namespace, identifier)
      name = File.basename(identifier)
      {
        raw: identifier,
        name: name,
        template_path: template_path(identifier),
        url: DeploymentServer.build_file_url(node_name, namespace, name)
      }
    end

    def template_path(identifier)
      name = File.basename(identifier)
      if url?(identifier)
        # Download the template to the Metalware cache; will render it from
        # there.
        # XXX Need to ensure cache template path is created.
        cache_template_path(name).tap do |template|
          Input.download(identifier, template)
        end
      elsif absolute_path?(identifier)
        # Path is an absolute path on the deployment server.
        identifier
      else
        # Path is within the repo `files` directory.
        repo_template_path(name)
      end
    end

    def url?(identifier)
      identifier =~ URI::regexp
    end

    def absolute_path?(identifier)
      Pathname.new(identifier).absolute?
    end

    def cache_template_path(template_name)
      File.join(Constants::CACHE_PATH, 'templates', template_name)
    end

    def repo_template_path(template_name)
      File.join(config.repo_path, 'files', template_name)
    end
  end
end
