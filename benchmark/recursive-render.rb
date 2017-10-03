# frozen_string_literal: true

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '../src')

require 'ruby-prof'
require 'cli'
require 'namespaces/alces'
require 'ostruct'

template = '/var/lib/metalware/repo/hosts/default'
config = Metalware::Config.new
alces = Metalware::Namespaces::Alces.new(config)

result = RubyProf.profile do
  begin
    STDERR.puts alces.render_erb_template(File.read(template))
  rescue => e
    STDERR.puts e.inspect
    # STDERR.puts e.backtrace
  end
end

printer = RubyProf::FlatPrinter.new(result)
printer.print($stdout)
