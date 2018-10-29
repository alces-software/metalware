
# frozen_string_literal: true

ruby '2.4.1'
source 'https://rubygems.org'

# Required to fix issue with FakeFS; refer to
# https://github.com/fakefs/fakefs#fakefs-----typeerror-superclass-mismatch-for-class-file.
require 'pp'

git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }

gem 'underware', path: '../underware'

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
gem 'activesupport'

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
