#!/usr/bin/env ruby

require 'rubygems'
require 'commander'

class MyApplication
  include Commander::Methods
  # include whatever modules you need

  def run
    program :name, 'metal'
    program :version, '0.0.1'
    program :description, 'Alces tools for the management and configuration of bare metal machines'

    command :repo do |c|
      c.syntax = 'metal repo [options]'
      c.summary = ''
      c.description = ''
      c.example 'description', 'command example'
      c.option '--some-switch', 'Some switch that does something'
      c.action do |args, options|
        # Do something or c.when_called Metal::Commands::Repo
      end
    end

    command :render do |c|
      c.syntax = 'metal render [options]'
      c.summary = ''
      c.description = ''
      c.example 'description', 'command example'
      c.option '--some-switch', 'Some switch that does something'
      c.action do |args, options|
        # Do something or c.when_called Metal::Commands::Render
      end
    end

    command :hosts do |c|
      c.syntax = 'metal hosts [options]'
      c.summary = ''
      c.description = ''
      c.example 'description', 'command example'
      c.option '--some-switch', 'Some switch that does something'
      c.action do |args, options|
        # Do something or c.when_called Metal::Commands::Hosts
      end
    end

    command :hunter do |c|
      c.syntax = 'metal hunter [options]'
      c.summary = ''
      c.description = ''
      c.example 'description', 'command example'
      c.option '--some-switch', 'Some switch that does something'
      c.action do |args, options|
        # Do something or c.when_called Metal::Commands::Hunter
      end
    end

    command :dhcp do |c|
      c.syntax = 'metal dhcp [options]'
      c.summary = ''
      c.description = ''
      c.example 'description', 'command example'
      c.option '--some-switch', 'Some switch that does something'
      c.action do |args, options|
        # Do something or c.when_called Metal::Commands::Dhcp
      end
    end

    command :build do |c|
      c.syntax = 'metal build [options]'
      c.summary = ''
      c.description = ''
      c.example 'description', 'command example'
      c.option '--some-switch', 'Some switch that does something'
      c.action do |args, options|
        # Do something or c.when_called Metal::Commands::Build
      end
    end

    run!
  end
end

MyApplication.new.run if $0 == __FILE__
