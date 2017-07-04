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

require 'fakefs/safe'

# XXX Reduce the hardcoded paths once sorted out Config/Constants situation.


class FileSystem
  def self.test(&block)
    # Ensure the FakeFS is in a fresh state. XXX needed?
    FakeFS.deactivate!
    FakeFS.clear!

    FakeFS do
      filesystem = new
      filesystem.create_initial_directory_hierarchy
      yield filesystem
    end
  end

  # This should construct the most minimal possible valid Metalware repo, at
  # the default repo path.
  def with_minimal_repo
    # XXX Create other parts of minimal repo.
    File.write '/var/lib/metalware/repo/configure.yaml', YAML.dump({
      questions: {},
      domain: {},
      group: {},
      node: {},
    })
  end

  def with_fixtures(fixtures_dir, at:)
    path = fixtures_path(fixtures_dir)
    FakeFS::FileSystem.clone(path, at)
  end

  # Create same directory hierarchy that would be created by a Metalware
  # install.
  def create_initial_directory_hierarchy
    [
      '/var/log/metalware',
      '/var/lib/metalware/rendered/kickstart',
      '/var/lib/metalware/rendered/system',
      '/var/lib/metalware/cache/built-nodes',
      '/var/lib/metalware/cache/templates',
      '/var/lib/metalware/repo',
      '/var/lib/metalware/answers/groups',
      '/var/lib/metalware/answers/nodes',
    ].each do |path|
      FileUtils.mkdir_p(path)
    end

    FileUtils.mkdir_p Metalware::Constants::METALWARE_CONFIGS_PATH
    FileUtils.touch Metalware::Constants::DEFAULT_CONFIG_PATH
  end

  private

  def fixtures_path(relative_fixtures_path)
    File.join(FIXTURES_PATH, relative_fixtures_path)
  end
end
