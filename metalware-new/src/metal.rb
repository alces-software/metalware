
# See http://stackoverflow.com/questions/837123/adding-a-directory-to-load-path-ruby.
$:.unshift File.dirname(__FILE__)

require 'rubygems'
require 'commander'

require 'commander_extensions'
require 'commands'

module Metalware
  class Cli
    include Commander::Methods
    include CommanderExtensions::Delegates

    def run
      program :name, 'metal'
      program :version, '2.0.0'
      program :description, 'Alces tools for the management and configuration of bare metal machines'

      command :repo do |c|
        c.syntax = 'metal repo [options]'
        c.summary = ''
        c.description = ''
        c.example 'description', 'command example'
        c.option '--some-switch', 'Some switch that does something'
        c.action Commands::Repo
      end

      command :render do |c|
        c.syntax = 'metal render [options]'
        c.summary = ''
        c.description = ''
        c.example 'description', 'command example'
        c.option '--some-switch', 'Some switch that does something'
        c.action Commands::Render
      end

      command :hosts do |c|
        c.syntax = 'metal hosts [options]'
        c.summary = ''
        c.description = ''
        c.example 'description', 'command example'
        c.option '--some-switch', 'Some switch that does something'
        c.action Commands::Hosts
      end

      command :hunter do |c|
        c.syntax = 'metal hunter [options]'
        c.summary = ''
        c.description = ''
        c.example 'description', 'command example'
        c.option '--some-switch', 'Some switch that does something'
        c.action Commands::Hunter
      end

      command :dhcp do |c|
        c.syntax = 'metal dhcp [options]'
        c.summary = ''
        c.description = ''
        c.example 'description', 'command example'
        c.option '--some-switch', 'Some switch that does something'
        c.action Commands::Dhcp
      end

      command :build do |c|
        c.syntax = 'metal build [options]'
        c.summary = ''
        c.description = ''
        c.example 'description', 'command example'
        c.option '--some-switch', 'Some switch that does something'
        c.action Commands::Build
      end

      run!
    end
  end
end
