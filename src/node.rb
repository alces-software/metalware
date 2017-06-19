
require 'open3'

require 'constants'
require 'system_command'
require 'nodeattr_interface'

module Metalware
  class Node
    attr_reader :name

    def initialize(config, name)
      @config = config
      @name = name
    end

    def hexadecimal_ip
      SystemCommand.run "gethostip -x #{name}"
    end

    def built?
      File.file? build_complete_marker_file
    end

    # The repo config files for this node in order of precedence from highest
    # to lowest.
    def configs
      [name, *groups, 'all'].reject(&:nil?).uniq
    end

    # Get the configured `files` for this node, to be rendered and used in
    # `build`. This is the merged namespaces with arrays of file identifiers
    # from all `files` namespaces within all configs for the node, with
    # identifiers in higher precedence configs replacing those with the same
    # basename in lower precendence configs.
    def build_files
      files_memo = Hash.new {|k,v| k[v] = []}
      configs.reverse.reduce(files_memo) do |files, config_name|
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
        @config.rendered_files_path,
        name,
        namespace.to_s,
        file_name
      )
    end

    private

    def build_complete_marker_file
      File.join(@config.built_nodes_storage_path, "metalwarebooter.#{name}")
    end

    def groups
      NodeattrInterface.groups_for_node(name)
    rescue NodeNotInGendersError
      # It's OK for a node to not be in the genders file, it just means it's
      # not part of any groups.
      []
    end

    def load_config(config_name)
      config_path = @config.repo_config_path(config_name)
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
