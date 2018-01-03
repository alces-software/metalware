
# frozen_string_literal: true

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '../src')

require 'ruby-prof'
require 'cli'
require 'namespaces/alces'
require 'ostruct'

module Metalware
  class MetalBench
    def self.run
      results = RubyProf.profile do
        begin
          STDERR.puts yield
        rescue StandardError => e
          puts e.message
          puts e.backtrace.inspect
        end
      end

      RubyProf::FlatPrinter.new(results).print($stdout)
    end
  end
end
