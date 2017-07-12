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

require 'minimal_repo'

# XXX Reduce the hardcoded paths once sorted out Config/Constants situation.


class FileSystem

  # Only interface to `FileSystem` is to call `FileSystem.setup` and then later
  # `test` on the resulting object, or to call `FileSystem.test` directly.
  private_class_method :new

  # Delegate file system handling methods appropriately here, so these can be
  # called on a `FileSystemConfigurator` instance and will then be correctly
  # invoked when `FileSystem.test` is run with that instance. If these were run
  # directly outside of a `test` block then the real file system would be used.
  delegate :mkdir_p, to: FileUtils

  # Perform optional configuration of the `FileSystem` prior to a `test`. The
  # yielded and returned `FileSystemConfigurator` caches any unknown method
  # calls it receives. When `test` is later called on it, it runs
  # `FileSystem#test` in the usual way but any cached `FileSystem` method calls
  # will be executed prior to yielding the setup `FileSystem` to the
  # user-passed block.
  #
  # Since there is a single global `FakeFS`, this has an advantage over running
  # method calls to set this up directly as it prevents it from being in an
  # inconsistent state, as well as ensuring the `FakeFS` is used only while the
  # `FakeFS do` block is executing in `test`.
  #
  # XXX This has the disadvantage that for calls which fail the exception is
  # not thrown from where the actual failing call is made; it could be worth
  # actually running the methods to check this, and then replaying them afresh
  # when `test` is run.
  def self.setup(&block)
    FileSystemConfigurator.new.tap do |configurator|
      yield configurator if block
    end
  end

  def self.test(configurator=FileSystemConfigurator.new, &block)
    # Ensure the FakeFS is in a fresh state. XXX needed?
    FakeFS.deactivate!
    FakeFS.clear!

    FakeFS do
      filesystem = new
      filesystem.create_initial_directory_hierarchy

      configurator.configure_filesystem(filesystem)

      yield filesystem
    end
  end

  # This should construct the most minimal possible valid Metalware repo, at
  # the default repo path.
  def with_minimal_repo
    MinimalRepo.create_at('/var/lib/metalware/repo')
  end

  def with_fixtures(fixtures_dir, at:)
    path = fixtures_path(fixtures_dir)
    FakeFS::FileSystem.clone(path, at)
  end

  def with_repo_fixtures(repo_fixtures_dir)
    # Create the minimal parts of a Metalware repo, these can then be
    # overridden by the specified fixtures.
    with_minimal_repo

    with_fixtures(repo_fixtures_dir, at: '/var/lib/metalware/repo')
  end

  def with_answer_fixtures(answer_fixtures_dir)
    with_fixtures(answer_fixtures_dir, at: '/var/lib/metalware/answers')
  end

  def with_groups_cache_fixture(groups_cache_file)
    with_fixtures(
      groups_cache_file,
      at: Metalware::Constants::GROUPS_CACHE_PATH
    )
  end

  def with_hunter_cache_fixture(hunter_cache_file)
    with_fixtures(
      hunter_cache_file,
      at: Metalware::Constants::HUNTER_PATH
    )
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

  # Print every directory and file loaded in the FakeFS.
  def debug!
    begin
      # This can fail oddly if nothing matches (see
      # https://github.com/fakefs/fakefs/issues/371), hence the `rescue` with a
      # simpler glob.
      matches = Dir['**/*']
    rescue NoMethodError
      matches = Dir['*']
    end

    matches.each do |path|
      identifier = File.file?(path) ? 'f' : 'd'
      puts "#{identifier}: #{path}"
    end
  end

  private

  def fixtures_path(relative_fixtures_path)
    File.join(FIXTURES_PATH, relative_fixtures_path)
  end

  class FileSystemConfigurator
    def initialize
      @method_calls = []
    end

    def method_missing(name, *args, &block)
      method_calls << MethodCall.new(name, args, block)
    end

    def configure_filesystem(filesystem)
      method_calls.each do |method|
        filesystem.send(method.name, *method.args, &method.block)
      end
    end

    def test(&block)
      FileSystem.test(self, &block)
    end

    private

    attr_reader :method_calls
  end

  MethodCall = Struct.new(:name, :args, :block)
end
