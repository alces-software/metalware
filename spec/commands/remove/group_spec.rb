# frozen_string_literal: true

#==============================================================================
# Copyright (C) 2017 Stephen F. Norledge and Alces Software Ltd.
#
# This file/package is part of Alces Metalware.
#
# Alces Metalware is free software: you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License
# as published by the Free Software Foundation, either version 3 of
# the License, or (at your option) any later version.
#
# Alces Metalware is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this package.  If not, see <http://www.gnu.org/licenses/>.
#
# For more information on the Alces Metalware, please visit:
# https://github.com/alces-software/metalware
#==============================================================================
require 'filesystem'
require 'commands/remove/group'
require 'nodeattr_interface'
require 'config'
require 'ostruct'

RSpec.describe Metalware::Commands::Remove::Group do
  let :filesystem do
    FileSystem.setup do |fs|
      fs.with_minimal_repo
      fs.with_answer_fixtures('setup1/answers')
    end
  end

  let :config { Metalware::Config.new }

  def generate_node_list(prefix, max_index: 10)
    [*1..max_index].map { |idx| "#{prefix}#{ "0" if idx < 10 }#{idx}" }
  end

  def run_remove_group(primary_group, primary_nodes)
    allow(Metalware::NodeattrInterface).to \
      receive(:nodes_in_primary_group).and_return(primary_nodes)

    filesystem.test do |_fs|
      answer_check = RSpecRemoveGroup::AnswerFileChecker
                       .new(self, config, primary_group, primary_nodes)
      Metalware::Commands::Remove::Group.new(primary_group, OpenStruct.new)
      answer_check.check
    end
  end

  context 'with no other groups' do
    it 'removes group and node answer files' do
      run_remove_group("nodes", generate_node_list("node"))
    end
  end

  context 'with a primary group that is used as an additional group' do
    it "remove the primary group without altering the other nodes" do |variable|
      run_remove_group("group1", generate_node_list("nodeA"))
    end
  end

  context 'with a nodes in an additional group (that is also primary)' do |variable|
    it 'does not remove the other additional group' do
      run_remove_group("group2", generate_node_list("nodeB"))
    end
  end
end

# Can only be ran inside RSpec AND FileSystem
module RSpecRemoveGroup
  class AnswerFileChecker
    def initialize(rspec_input, metal_config, group_input, nodes_input)
      @config = metal_config
      @primary_group = group_input
      @primary_nodes = nodes_input
      @initial_files = answer_files
      @rspec = rspec_input
    end

    def check
      # Checks that we haven't deleted the wrong file
      rspec.expect(deleted_files - expected_deleted_files).to rspec.be_empty
      # Checks that all files that should be deleted have been
      expected_deleted_files.each do |deleted_file|
        msg = "Expected file to be deleted: #{deleted_file}"
        rspec.expect(File.file?(deleted_file)).to rspec.be(false), msg
      end
    end

    private

    def deleted_files
      answer_files - initial_files
    end

    def expected_deleted_files
      @expected_deleted_files ||= begin
        primary_nodes.map { |node| "nodes/#{node}.yaml" }
                     .unshift(["groups/#{primary_group}.yaml"])
                     .map { |f| File.join(config.answer_files_path, f) }
      end
    end

    def answer_files
      Dir[File.join(config.answer_files_path, "**/*.yaml")]
    end

    attr_reader :config, :initial_files, :primary_group, :primary_nodes, :rspec
  end
end