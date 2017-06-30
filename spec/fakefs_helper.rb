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
require 'constants'

class FakeFSHelper
  def initialize(metal_config)
    @metal_config = metal_config
    FakeFS.deactivate!
    FakeFS.clear!
  end

  def run(&block)
    FakeFS do yield end
  end

  # TODO: Replace this with clone_answers
  def add_answer_files(files)
    FakeFS::FileUtils.mkdir_p(Metalware::Constants::ANSWERS_PATH)
    files = [files] if files.is_a?(String)
    files.each do |f|
      d = File.join(Metalware::Constants::ANSWERS_PATH, File.basename(f))
      FakeFS::FileSystem.clone(f, d)
    end
  end

  def clone_answers(path = Metalware::Constants.ANSWERS_PATH)
    FakeFS::FileSystem.clone(path, Metalware::Constants::ANSWERS_PATH)
  end

  # Deprecated, please use clone_repo
  def load_repo(path = @metal_config.repo_path)
    FakeFS::FileSystem.clone(path, @metal_config.repo_path)
  end

  # Deprecated, please use clone_repo
  # TODO: remove references to load_config_files
  def load_config_files(config_names = [])
    FakeFS::FileSystem.clone(@metal_config.configure_file)
    config_names.each do |c|
      FakeFS::FileSystem.clone(@metal_config.repo_config_path(c))
    end
  end


  def clone(*a)
    FakeFS::FileSystem.clone(*a)
  end

  def clone_repo(path = @metal_config.repo_path)
    FakeFS::FileSystem.clone(path, @metal_config.repo_path)
  end

  def clear
    FakeFS.clear!
  end
end
