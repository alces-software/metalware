
# frozen_string_literal: true

ruby '2.4.1'
source 'https://rubygems.org'

# Required to fix issue with FakeFS; refer to
# https://github.com/fakefs/fakefs#fakefs-----typeerror-superclass-mismatch-for-class-file.
require 'pp'

gem 'colorize'
gem 'commander', git: 'https://github.com/alces-software/commander'
gem 'dry-validation'
gem 'hashie'
gem 'highline', '1.7.8'
gem 'net-dhcp'
gem 'network_interface', '~> 0.0.1'
gem 'pcap', git: 'https://github.com/alces-software/ruby-pcap.git'
gem 'recursive-open-struct'
gem 'ruby-libvirt'
gem 'rugged'
gem 'terminal-table'

# Forked of a fork containing a logger fix. The main gem can be used
# again once StructuredWarnings is removed
gem 'rubytree', git: 'https://github.com/alces-software/RubyTree'

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

# Gems added for GUI app.
gem 'bootstrap'
gem 'concurrent-ruby', require: 'concurrent'
gem 'jquery-rails' # Required for Bootstrap.

# Required as Rails need a JavaScript runtime.
gem 'therubyracer'

# Copied from Rails-generated Gemfile below this point.

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.1.3'
# Use Puma as the app server
gem 'puma', '~> 3.7'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 3.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution
  # and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %>
  # anywhere in the code.
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'web-console', '>= 3.3.0'
  # Spring speeds up development by keeping your application running in the
  # background. Read more: https://github.com/rails/spring
  gem 'ruby-prof'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
