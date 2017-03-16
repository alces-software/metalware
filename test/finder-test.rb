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

require "alces/stack/finder"

class TC_Templater_Finder < Test::Unit::TestCase
  def setup
    @default_kickstart = "#{ENV['alces_REPO']}/templates/kickstart/".gsub("//","/")
    @default_boot = "#{ENV['alces_REPO']}/templates/boot/".gsub("//","/")
    @tmp_folder = "#{@default_kickstart}tempfolderthatshouldnotexist/"
    @tmp_file = "#{@tmp_folder}local.erb"
    @tmp_file2 = "#{@default_kickstart}local-boot.erb"
    @tmp_file3 = "#{@default_kickstart}local_boot.erb"
    `mkdir #{@tmp_folder}`
    `echo "A whole bunch of nothing" > #{@tmp_file}`
    `echo "A whole bunch of nothing" > #{@tmp_file2}`
    `echo "A whole bunch of nothing" > #{@tmp_file3}`
  end

  def teardown 
    `rm -rf #{@tmp_folder}`
    `rm -f #{@tmp_file2}`
    `rm -f #{@tmp_file3}`
  end

  def test_find_kickstart
    fullpath  = "#{@default_kickstart}compute.erb"
    tmp_fullpath  = "#{@default_kickstart}local.erb"
    find = Alces::Stack::Finder.new(@default_kickstart, "#{@default_kickstart}/compute.erb")
    assert_equal(fullpath, find.template, "Could not find file from full path")
    find = Alces::Stack::Finder.new(@default_kickstart, "#{@default_kickstart}/compute")
    assert_equal(fullpath, find.template, "Could not find file from full path with no .ext")
    find = Alces::Stack::Finder.new(@default_kickstart, "/compute.erb")
    assert_equal(fullpath, find.template, "Could not find file from name")
    find = Alces::Stack::Finder.new(@default_kickstart, "compute")
    assert_equal(fullpath, find.template, "Could not find file from name no .ext")
    find = Alces::Stack::Finder.new(@default_kickstart, "tempfolderthatshouldnotexist/local.erb")
    assert_equal(@tmp_file, find.template, "Found nested template")
    assert_raise Alces::Stack::Finder::TemplateNotFound do Alces::Stack::Finder.new(@default_kickstart, template = "local") end
    find = Alces::Stack::Finder.new(@default_kickstart, "local-boot")
    assert_equal(@tmp_file2, find.template, "Could not find file with a -")
    find = Alces::Stack::Finder.new(@default_kickstart, "local_boot")
    assert_equal(@tmp_file3, find.template, "Could not find file with a _")
  end

  def test_find_boot
    fullpath = "#{@default_boot}install.erb"
    find = Alces::Stack::Finder.new(@default_boot, "install")
    assert_equal(fullpath, find.template, "Could not find boot template")
  end

  def test_path
    fullpath = "#{@default_boot}install.erb"
    find = Alces::Stack::Finder.new(@default_boot, "install")
    assert_equal(@default_boot, find.path << "/", "Did not return correct path to template")
  end

  def test_filename
    find = Alces::Stack::Finder.new(@default_kickstart, "compute")
    assert_equal("compute", find.filename, "Did not return correct filename or ext")
    assert_equal("compute.erb", find.filename_ext, "Did not return correct filename or ext")
    assert_equal("compute.ks", find.filename_diff_ext("ks"), "Did not return correct filename or ext")
    assert_equal("compute.ks", find.filename_diff_ext(".ks"), "Did not return correct filename or ext")
    assert_equal("compute.ks", find.filename_diff_ext(".ks"), "Did not return correct filename or ext")
    find = Alces::Stack::Finder.new(@default_kickstart, "local-boot")
    assert_equal("local-boot", find.filename, "Did not find filename with -")
    find = Alces::Stack::Finder.new(@default_kickstart, "local_boot")
    assert_equal("local_boot", find.filename, "Did not find filename with _")
    assert_raise Alces::Stack::Finder::TemplateNotFound do Alces::Stack::Finder.new(@default_kickstart, "") end
    assert_raise Alces::Stack::Finder::TemplateNotFound do Alces::Stack::Finder.new(@default_kickstart, nil) end
  end
end