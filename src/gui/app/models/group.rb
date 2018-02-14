
# frozen_string_literal: true

class Group < ApplicationModel
  class << self
    def all
      group_cache.primary_groups.map { |name| Group.new(name) }
    end

    private

    def group_cache
      Metalware::GroupCache.new
    end
  end

  attr_reader :name

  def initialize(name)
    @name = name
  end

  def nodes
    # XXX We may or may not want to get just nodes with this as a primary group
    # here. Both ways could be confusing as we are inconsistent with which we
    # use, e.g. when we build a group nodes in that group but without it as
    # their primary group will still be included, but they won't be included
    # here.
    Metalware::NodeattrInterface.nodes_in_group(name).map do |name|
      Metalware::Node.new(config, name)
    end
  end
end
