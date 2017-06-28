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

require 'fakefs_helper'
require 'spec_helper'
require 'fileutils'

RSpec.describe Metalware::Dependencies do
  context 'repo dependencies' do
    before :each do
      @config = Metalware::Config.new
      @fshelper = FakeFSHelper.new(@config)
      @fshelper.load_repo(File.join(FIXTURES_PATH, "repo"))
    end

    def run_dependencies(config, command, dep = {})
      @fshelper.run do
        Metalware::Dependencies.new(config, command, dep).enforce
      end
    end

    it 'fails if the repo doesn\'t exist' do
      @fshelper.clear
      expect {
        run_dependencies(@config, "test", { repo: true })
      }.to raise_error(Metalware::DependencyFailure)
    end

    it 'check if the base repo exists' do
      expect {
        run_dependencies(@config, "test", { repo: true })
      }.not_to raise_error
    end

    it 'check if repo directories exist' do
      expect {
        run_dependencies(@config, "test", {
          repo: "dependency-test1"
        })
      }.not_to raise_error
      expect {
        run_dependencies(@config, "test", {
          repo: ["dependency-test1", "dependency-test2"]
        })
      }.not_to raise_error
    end

    it 'check if repo directories doesn\'t exist' do
      expect {
        run_dependencies(@config, "test", {
          repo: "not-found"
        })
      }.to raise_error(Metalware::DependencyFailure)
    end
  end
end
