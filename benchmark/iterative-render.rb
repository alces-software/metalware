$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '../src')

require 'ruby-prof'
require 'cli'
require 'ostruct'

template = '/var/lib/metalware/repo/hosts/default'

RubyProf.start
  Metalware::Commands::Render.new(template, OpenStruct.new({}))
result = RubyProf.stop

printer = RubyProf::FlatPrinter.new(result)
printer.print($stdout)
