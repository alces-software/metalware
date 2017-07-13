
# XXX Possibly more behaviour should be moved here, from
# `Templating::GroupNamespace` and/or `Nodes` classes.
module Metalware
  class PrimaryGroup
    class << self
      include Enumerable

      def each(&block)
        cached_primary_groups.each do |group_name|
          yield new(group_name)
        end
      end

      def index(primary_group_name)
        find_index do |primary_group|
          primary_group.name == primary_group_name
        end
      end

      private

      def cached_primary_groups
        groups_cache[:primary_groups] || []
      end

      def groups_cache
        Data.load(Constants::GROUPS_CACHE_PATH)
      end
    end

    attr_reader :name

    def initialize(name)
      @name = name
    end
  end
end
