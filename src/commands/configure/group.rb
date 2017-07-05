
require 'command_helpers/configure_command'
require 'constants'
require 'utils'


module Metalware
  module Commands
    module Configure

      class Group < CommandHelpers::ConfigureCommand
        def setup(args, _options)
          @group_name = args.first
        end

        def run
          super
          record_primary_group
        end

        protected

        def answers_file
          file_name = "#{group_name}.yaml"
          File.join(config.answer_files_path, 'groups', file_name)
        end

        private

        attr_reader :group_name

        def record_primary_group
          unless primary_group_recorded?
            primary_groups << group_name
            File.write(groups_cache_file, YAML.dump(groups_cache))
          end
        end

        def primary_group_recorded?
          primary_groups.include? group_name
        end

        def primary_groups
          groups_cache[:primary_groups] ||= []
        end

        def groups_cache
          @groups_cache ||= Utils.safely_load_yaml(groups_cache_file)
        end

        def groups_cache_file
          File.join(Constants::CACHE_PATH, 'groups.yaml')
        end
      end

    end
  end
end
