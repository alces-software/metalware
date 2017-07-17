
# frozen_string_literal: true

require 'command_helpers/configure_command'
require 'constants'

module Metalware
  module Commands
    module Configure
      class Group < CommandHelpers::ConfigureCommand
        def setup(args, _options)
          @group_name = args.first
        end

        protected

        def custom_configuration
          record_primary_group
        end

        def answers_file
          file_name = "#{group_name}.yaml"
          File.join(config.answer_files_path, 'groups', file_name)
        end

        private

        attr_reader :group_name

        def record_primary_group
          unless primary_group_recorded?
            primary_groups << group_name
            Data.dump(Constants::GROUPS_CACHE_PATH, groups_cache)
          end
        end

        def primary_group_recorded?
          primary_groups.include? group_name
        end

        def primary_groups
          groups_cache[:primary_groups] ||= []
        end

        def groups_cache
          @groups_cache ||= Data.load(Constants::GROUPS_CACHE_PATH)
        end
      end
    end
  end
end
