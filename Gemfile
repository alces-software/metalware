
ruby '2.4.1'
source 'https://rubygems.org'

# Required to fix issue with FakeFS; refer to
# https://github.com/fakefs/fakefs#fakefs-----typeerror-superclass-mismatch-for-class-file.
require 'pp'

gem 'commander', git: 'https://github.com/alces-software/commander'
gem 'rugged'
gem 'activesupport'
gem 'recursive-open-struct'
gem 'pcap', git: 'https://github.com/alces-software/ruby-pcap.git'
gem 'net-dhcp'
gem 'hashie'
gem 'fakefs'
gem 'highline', '1.7.8'
gem 'dry-validation'

group :test do
  gem 'rspec'
  gem 'simplecov'
end

group :development, :test do
  gem 'rubocop', require: false
end
