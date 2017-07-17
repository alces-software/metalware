
# frozen_string_literal: true

ruby '2.4.1'
source 'https://rubygems.org'

# Required to fix issue with FakeFS; refer to
# https://github.com/fakefs/fakefs#fakefs-----typeerror-superclass-mismatch-for-class-file.
require 'pp'

gem 'activesupport'
gem 'commander', git: 'https://github.com/alces-software/commander'
gem 'dry-validation'
gem 'fakefs'
gem 'hashie'
gem 'highline', '1.7.8'
gem 'net-dhcp'
gem 'pcap', git: 'https://github.com/alces-software/ruby-pcap.git'
gem 'recursive-open-struct'
gem 'rugged'

group :test do
  gem 'rspec'
  gem 'simplecov'
end

group :development, :test do
  gem 'rubocop', require: false
end
