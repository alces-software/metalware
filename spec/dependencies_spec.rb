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
require 'exceptions'
require 'dependencies'
require 'config'
require 'constants'

require 'fakefs_helper'
require 'spec_helper'
require 'fileutils'

RSpec.describe Metalware::Dependencies do
  before :each do
    @config = Metalware::Config.new
    @fshelper = FakeFSHelper.new(@config)
    @fshelper.load_repo(File.join(FIXTURES_PATH, "repo"))
  end

  def run_dependencies(config, dep = {})
    @fshelper.run do
      Metalware::Dependencies.new(config, "test", dep).enforce
    end
  end

  context 'repo dependencies' do
    it 'fails if the repo doesn\'t exist' do
      @fshelper.clear
      expect {
        run_dependencies(@config, { repo: [] })
      }.to raise_error(Metalware::DependencyFailure)
    end

    it 'check if the base repo exists' do
      expect {
        run_dependencies(@config, { repo: [] })
      }.not_to raise_error
    end

    it 'check if repo template exists' do
      expect {
        run_dependencies(@config, {
          repo: ["dependency-test1/default"]
        })
      }.not_to raise_error
      expect {
        run_dependencies(@config, {
          repo: ["dependency-test1/default", "dependency-test2/default"]
        })
      }.not_to raise_error
    end

    it 'fail if repo template doesn\'t exist' do
      expect {
        run_dependencies(@config, {
          repo: ["dependency-test1/not-found"]
        })
      }.to raise_error(Metalware::DependencyFailure)
    end

    it 'fail if validating a repo directory' do
      expect {
        run_dependencies(@config, {
          repo: ["dependency-test1"]
        })
      }.to raise_error(Metalware::DependencyFailure)
    end
  end

  context 'configure dependencies' do
    before :each do
      @fshelper.clone_answers(File.join(FIXTURES_PATH, "answers/basic_structure"))
    end

    it 'fails if the repo doesn\'t exist' do
      @fshelper.clear
      expect {
        run_dependencies(@config, { configure: ["domain.yaml"] })
      }.to raise_error(Metalware::DependencyFailure)
    end

    # NOTE: This is the backwards compatibility test
    it 'pass if the repo exists but configure.yaml doens\'t' do
      @fshelper.run do
        File.delete(File.join(@config.repo_path, "configure.yaml"))
        File.delete(File.join(Metalware::Constants::ANSWERS_PATH, "domain.yaml"))
      end

      expect {
        run_dependencies(@config, { configure: ["domain.yaml"] })
      }.not_to raise_error
    end

    it 'fails if answers directory doesn\'t exist' do
      @fshelper.run do
        File.delete(Metalware::Constants::ANSWERS_PATH)
      end

      expect {
        run_dependencies(@config, { configure: ["domain.yaml"] })
      }.to raise_error(Metalware::DependencyFailure)
    end

    it 'validates that the answer files exists' do
      expect {
        run_dependencies(@config,
                         { configure: ["domain.yaml", "groups/group1.yaml"] })
      }.not_to raise_error
    end

    it 'validates missing answer files' do
      @fshelper.run do
        File.delete(File.join(Metalware::Constants::ANSWERS_PATH, "groups/group1.yaml"))
      end

      expect {
        run_dependencies(@config,
                         { configure: ["domain.yaml", "groups/group1.yaml"] })
      }.to raise_error(Metalware::DependencyFailure)
    end
  end
end
