
# frozen_string_literal: true

ruby '2.4.1'
source 'https://rubygems.org'

# Required to fix issue with FakeFS; refer to
# https://github.com/fakefs/fakefs#fakefs-----typeerror-superclass-mismatch-for-class-file.
require 'pp'

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

# We want Underware to be installed at a sibling directory to Metalware (so it
# can be used as an entirely independent tool in its own right), but also want
# to lock down the Underware version so we fail fast if the installed Underware
# in this directory is not what we require. The required version of Underware
# is loaded from a file so we can easily have this version installed by
# Metalware itself in production (or CI) if needed.
underware_version = File.read('underware-version').chomp
gem 'underware', underware_version, path: '../underware'

gem 'activesupport'
gem 'colorize'
gem 'commander', github: 'alces-software/commander'
gem 'dry-validation'
gem 'hashie'
gem 'highline', '1.7.8'
gem 'net-dhcp'
gem 'network_interface', '~> 0.0.1'
gem 'pcap', github: 'alces-software/ruby-pcap'
gem 'recursive-open-struct'
gem 'ruby-libvirt'
gem 'rugged'
gem 'terminal-table'

# Forked of a fork containing a logger fix. The main gem can be used
# again once StructuredWarnings is removed
gem 'rubytree', github: 'alces-software/RubyTree'

group :test do
  gem 'fakefs'
  gem 'rspec'
  gem 'simplecov'
end

group :development do
  gem 'pry'
  gem 'rubocop', '~> 0.52.1', require: false
  gem 'rubocop-rspec'
end
