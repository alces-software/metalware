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
require_relative "#{ENV['alces_BASE']}/test/helper/base-test-require.rb" 
require "fileutils"

class TC_Repo < Test::Unit::TestCase
  def setup
    @bash = File.read("/etc/profile.d/alces-metalware.sh")
  end

  def test_clone
    `#{@bash} metal repo -cn new_repo -r https://github.com/alces-software/metalware-default.git`
    assert(Dir["/var/lib/metalware/repos/new_repo/*"].count > 0,
           "Repo was not cloned correctly")
  end

  def test_repo_already_exists
    repo = "/var/lib/metalware/repos/name"
    FileUtils::mkdir_p "#{repo}/file"

    `#{@bash} metal repo -cn name -r https://github.com/alces-software/metalware-default.git 2>/dev/null`
    assert(Dir["#{repo}/*"].count == 1, "Clone override existing repo without -f")

    `#{@bash} metal repo -fcn name -r https://github.com/alces-software/metalware-default.git`
    assert(Dir["#{repo}/*"].count > 1, "Clone did not override existing repo with -f")
  end

  def teardown
    Dir.entries("/var/lib/metalware/repos").each do |repo|
      unless [".", "..", "default"].include? repo
        FileUtils.rm_rf("/var/lib/metalware/repos/#{repo}")
      end
    end
  end
end