#!/opt/metalware/opt/ruby/bin/ruby

# Stick this as `/opt/metalware/show_config`.

require_relative 'src/cli.rb'
require 'json'

node = ARGV.first
templater = Metalware::Templater.new(Metalware::Config.new, {nodename: node})
puts JSON.pretty_generate(templater.config.to_h)
