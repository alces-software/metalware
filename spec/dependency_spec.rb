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
require 'dependency'
require 'config'
require 'constants'
require 'configurator'

require 'fakefs_helper'
require 'spec_helper'
require 'fileutils'

RSpec.describe Metalware::Dependency do
  let :config { Metalware::Config.new }
  let :fshelper { FakeFSHelper.new(config) }

  def enforce_dependencies(dependency_hash = {})
    fshelper.run do
      Metalware::Dependency.new(config, "test", dependency_hash).enforce
    end
  end

  context 'with a blank filesystem' do
    before :each do
      allow(Metalware::Configurator).to \
        receive(:valid_configure_file?).and_return(true)
    end

    it 'repo dependencies fail' do
      expect {
        enforce_dependencies({ repo: [] })
      }.to raise_error(Metalware::DependencyFailure)
    end

    it 'configure dependencies fail' do
      expect {
        enforce_dependencies({ configure: ["domain.yaml"] })
      }.to raise_error(Metalware::DependencyFailure)
    end
  end

  context 'with repo dependencies' do
    before :each do
      fshelper.clone_repo(File.join(FIXTURES_PATH, "repo"))
      allow(Metalware::Configurator).to \
        receive(:valid_configure_file?).and_return(true)
    end

    it 'check if the base repo exists' do
      expect {
        enforce_dependencies({ repo: [] })
      }.not_to raise_error
    end

    it 'check if repo template exists' do
      expect {
        enforce_dependencies({
          repo: ["dependency-test1/default"]
        })
      }.not_to raise_error
      expect {
        enforce_dependencies({
          repo: ["dependency-test1/default", "dependency-test2/default"]
        })
      }.not_to raise_error
    end

    it "fail if repo template doesn't exist" do
      expect {
        enforce_dependencies({
          repo: ["dependency-test1/not-found"]
        })
      }.to raise_error(Metalware::DependencyFailure)
    end

    it 'fail if validating a repo directory' do
      expect {
        enforce_dependencies({
          repo: ["dependency-test1"]
        })
      }.to raise_error(Metalware::DependencyFailure)
    end
  end

  context 'with blank configure.yaml dependencies' do
    before :each do
      fshelper.clone_repo(File.join(FIXTURES_PATH, "repo"))
      fshelper.clone_answers(File.join(FIXTURES_PATH, "answers/basic_structure"))
      allow(Metalware::Configurator).to \
        receive(:valid_configure_file?).and_return(true)
    end

    it "fails if answers directory doesn't exist" do
      fshelper.run do
        File.delete(config.answer_files_path)
      end

      expect {
        enforce_dependencies({ configure: ["domain.yaml"] })
      }.to raise_error(Metalware::DependencyFailure)
    end

    it 'validates that the answer files exists' do
      expect {
        enforce_dependencies(
                         { configure: ["domain.yaml", "groups/group1.yaml"] })
      }.not_to raise_error
    end

    it 'validates missing answer files' do
      fshelper.run do
        File.delete(File.join(config.answer_files_path, "groups/group1.yaml"))
      end

      expect {
        enforce_dependencies(
                         { configure: ["domain.yaml", "groups/group1.yaml"] })
      }.to raise_error(Metalware::DependencyFailure)
    end
  end
end
