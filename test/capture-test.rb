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
ENV['BUNDLE_GEMFILE'] ||= "#{ENV['alces_BASE']}/lib/ruby/Gemfile"
$: << "#{ENV['alces_BASE']}/lib/ruby/lib"

require 'rubygems'
require 'bundler/setup'
Bundler.setup(:default)
require 'test/unit'

require "alces/stack/capture"

class TC_Capture < Test::Unit::TestCase
  def test_stdout
    capture = Alces::Stack::Capture.stdout do puts "Captured" end
    puts "\nreset" 
    assert(!capture.include?("\nreset"), "Capture has not reset standard out")
    assert(capture.include?("Captured"), "Capture did not capture standard out text")
  end
  def test_stderr
    capture = Alces::Stack::Capture.stderr do $stderr.puts "Captured" end
    $stderr.puts "\nreset" 
    assert(!capture.include?("\nreset"), "Capture has not reset standard error")
    assert(capture.include?("Captured"), "Capture did not capture standard error text")
  end
end 
