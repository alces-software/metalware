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
require 'exceptions'
require 'dependency'
require 'constants'
require 'validation/configure'
require 'ostruct'

require 'spec_helper'
require 'fileutils'
require 'filesystem'
require 'alces_utils'

RSpec.describe Metalware::Dependency do
  include AlcesUtils

  let(:filesystem) { FileSystem.setup }

  def enforce_dependencies(dependencies_hash = {})
    filesystem.test do |_fs|
      Metalware::Dependency.new('test', dependencies_hash).enforce
    end
  end

  context 'with a fresh filesystem' do
    it 'repo dependencies fail' do
      expect do
        enforce_dependencies(repo: [])
      end.to raise_error(Metalware::DependencyFailure)
    end

    it 'configure dependencies fail' do
      expect do
        enforce_dependencies(configure: ['domain.yaml'])
      end.to raise_error(Metalware::DependencyFailure)
    end
  end

  context 'with repo dependencies' do
    before do
      filesystem.with_repo_fixtures('repo')
    end

    it 'check if the base repo exists' do
      expect do
        enforce_dependencies(repo: [])
      end.not_to raise_error
    end

    it 'check if repo template exists' do
      expect do
        enforce_dependencies(repo: ['dependency-test1/default'])
      end.not_to raise_error
      expect do
        template = ['dependency-test1/default', 'dependency-test2/default']
        enforce_dependencies(repo: template)
      end.not_to raise_error
    end

    it "fail if repo template doesn't exist" do
      expect do
        enforce_dependencies(repo: ['dependency-test1/not-found'])
      end.to raise_error(Metalware::DependencyFailure)
    end

    it 'fail if validating a repo directory' do
      expect do
        enforce_dependencies(repo: ['dependency-test1'])
      end.to raise_error(Metalware::DependencyFailure)
    end
  end

  context 'with blank configure.yaml dependencies' do
    before do
      filesystem.with_repo_fixtures('repo')
    end

    it 'validates missing answer files' do
      filesystem.test do
        expect do
          enforce_dependencies(
            configure: ['domain.yaml', 'groups/group1.yaml']
          )
        end.to raise_error(Metalware::DependencyFailure)
      end
    end

    # The orphan group does not require an answer file
    it 'does not validate groups/orphan.yaml' do
      filesystem.test do
        expect do
          enforce_dependencies(
            configure: ['groups/orphan.yaml']
          )
        end.not_to raise_error
      end
    end

    context 'when answer files exist' do
      before do
        filesystem.with_minimal_repo
        filesystem.with_answer_fixtures('answers/basic_structure')
      end

      it 'validates that the answer files exists' do
        expect do
          enforce_dependencies(
            configure: ['domain.yaml', 'groups/group1.yaml']
          )
        end.not_to raise_error
      end
    end

    context 'with optional dependencies' do
      before do
        filesystem.with_minimal_repo
        filesystem.with_answer_fixtures('answers/basic_structure')
      end

      it 'skips a single missing file' do
        expect do
          enforce_dependencies(
            optional: {
              configure: ['not_found.yaml'],
            }
          )
        end.not_to raise_error
      end

      it 'validates a correct answer file' do
        expect do
          enforce_dependencies(
            optional: {
              configure: ['domain.yaml', 'not_found.yaml'],
            }
          )
        end.not_to raise_error
      end
    end
  end
end
