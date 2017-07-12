
module Metalware
  module Templating
    class GroupNamespace
      attr_reader :name

      def initialize(metalware_config, group_name)
        @metalware_config = metalware_config
        @name = group_name
      end

      # XXX refactor all answers duplication with `Node`.
      def answers
        @answers ||= combine_answers
      end

      private

      # XXX duplicated from `Node`.
      def combine_answers
        config_answers = configs.map { |c| Data.load(answers_path_for(c)) }
        combine_hashes(config_answers)
      end

      # The repo config files for this group in order of precedence from lowest
      # to highest.
      # XXX adapted from `Node`.
      def configs
        ['domain', name]
      end

      # XXX duplicated from `Node`.
      def answers_path_for(config_name)
        File.join(
          @metalware_config.answer_files_path,
          answers_directory_for(config_name),
          "#{config_name}.yaml"
        )
      end

      # XXX adapted from `Node`.
      def answers_directory_for(config_name)
        # XXX Using only the config name to determine the answers directory will
        # lead to answers not being picked up if a group has the same name as the
        # node, or either is 'domain'; we should probably use more information
        # when determining this (possibly we should extract a `Config` object).
        case config_name
        when "domain"
          "/"
        when name
          "groups"
        end
      end

      # XXX duplicated from `Node`.
      def combine_hashes(hashes)
        hashes.each_with_object({}) do |config, combined_config|
          raise CombineHashError unless config.is_a? Hash
          combined_config.deep_merge!(config)
        end
      end
    end
  end
end
