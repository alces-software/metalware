
require 'open3'

require 'constants'
require 'system_command'
require 'nodeattr_interface'
require 'exceptions'

module Metalware
  class Node
    attr_reader :name

    def initialize(metalware_config, name)
      @metalware_config = metalware_config
      @name = name
    end

    def hexadecimal_ip
      SystemCommand.run "gethostip -x #{name}"
    end

    def built?
      File.file? build_complete_marker_file
    end

    # Return the raw merged config for this node, without parsing any embedded
    # ERB (this should be done using the Templater if needed, as we won't know
    # all the template parameters until a template is being rendered).
    # XXX refactor this to use `load_config`, and use this from `build_files`.
    def raw_config
      combined_configs = {}
      configs.each do |config_name|
        begin
          config_path = "#{@metalware_config.repo_path}/config/#{config_name}.yaml"
          config = YAML.load_file(config_path)
        rescue Errno::ENOENT # Skips missing files
        rescue StandardError
          raise YAMLConfigError, "Could not parse YAML config file"
        else
          if !config.is_a? Hash
            raise YAMLConfigError, "Expected YAML config file to contain a hash"
          else
            combined_configs.deep_merge!(config)
          end
        end
      end
      combined_configs.deep_transform_keys{ |k| k.to_sym }
    end

    # The repo config files for this node in order of precedence from lowest to
    # highest.
    def configs
      [name, *groups, 'all'].reverse.reject(&:nil?).uniq
    end

    # Get the configured `files` for this node, to be rendered and used in
    # `build`. This is the merged namespaces with arrays of file identifiers
    # from all `files` namespaces within all configs for the node, with
    # identifiers in higher precedence configs replacing those with the same
    # basename in lower precendence configs.
    def build_files
      files_memo = Hash.new {|k,v| k[v] = []}
      configs.reduce(files_memo) do |files, config_name|
        config = load_config(config_name)
        new_files = config[:files]
        merge_in_files!(files, new_files)
        files
      end.symbolize_keys
    end

    # The path the file with given `file_name` within the given `namespace`
    # will be rendered to for this node.
    def rendered_build_file_path(namespace, file_name)
      File.join(
        @metalware_config.rendered_files_path,
        name,
        namespace.to_s,
        file_name
      )
    end

    private

    def build_complete_marker_file
      File.join(@metalware_config.built_nodes_storage_path, "metalwarebooter.#{name}")
    end

    def groups
      NodeattrInterface.groups_for_node(name)
    rescue NodeNotInGendersError
      # It's OK for a node to not be in the genders file, it just means it's
      # not part of any groups.
      []
    end

    def load_config(config_name)
      config_path = @metalware_config.repo_config_path(config_name)
      if File.exist? config_path
        YAML.load_file(config_path).symbolize_keys
      else
        {}
      end
    end

    def merge_in_files!(existing_files, new_files)
      if new_files
        new_files.each do |namespace, file_identifiers|
          file_identifiers.each do |file_identifier|
            replace_file_with_same_basename!(existing_files[namespace], file_identifier)
          end
        end
      end
    end

    def replace_file_with_same_basename!(files_namespace, file_identifier)
      # XXX May want to give a warning here when replacing a file.
      files_namespace.reject! {|f| same_basename?(file_identifier, f)}
      files_namespace << file_identifier
      files_namespace.sort! # Sort for consistent ordering.
    end

    def same_basename?(path1, path2)
      File.basename(path1) == File.basename(path2)
    end
  end
end
