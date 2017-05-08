
# See http://stackoverflow.com/questions/837123/adding-a-directory-to-load-path-ruby.
$:.unshift File.dirname(__FILE__)

require 'rubygems'
require 'commander'

require 'commander_extensions'
require 'commands'

# TODO: For `hosts` and `build` decide if we want to distinguish operating on
# nodes vs groups by:
# - using exclusive `-n`/`-g` options;
# - using `node` and `group` subcommands;
# - making node operations the default, and `-g` switches the command to
# operate on a group

module Metalware
  class Cli
    include Commander::Methods
    include CommanderExtensions::Delegates

    def run
      program :name, 'metal'
      program :version, '2.0.0'
      program :description, 'Alces tools for the management and configuration of bare metal machines'

      command :'repo use' do |c|
        c.syntax = 'metal repo use REPO_URL [options]'
        c.summary = ''
        c.description = ''
        c.example 'description', 'command example'
        c.option '--force', '-f',
          'Force use of a new repo even if local changes have been made to the current repo'
        c.action Commands::Repo::Use
      end

      command :'repo update' do |c|
        c.syntax = 'metal repo update [options]'
        c.summary = ''
        c.description = ''
        c.example 'description', 'command example'
        c.option '--force', '-f',
          'Force update even if local changes have been made to the repo'
        c.action Commands::Repo::Update
      end

      command :render do |c|
        c.syntax = 'metal render TEMPLATE [NODE] [options]'
        c.summary = ''
        c.description = ''
        c.example 'description', 'command example'
        c.action Commands::Render
      end

      command :hosts do |c|
        c.syntax = 'metal hosts [options]'
        c.summary = ''
        c.description = ''
        c.example 'description', 'command example'
        c.option '--node STRING', '-n', String, 'Node name'
        c.option '--group STRING', '-g', String, 'Gender group'
        c.option '--template STRING', '-t', String, 'Specify hosts template to use'
        c.option '--dry-run', '-x',
          'Do not modify hosts file, just output additions that would be made'
        c.action Commands::Hosts
      end

      command :hunter do |c|
        c.syntax = 'metal hunter [options]'
        c.summary = ''
        c.description = ''
        c.example 'description', 'command example'
        c.option '--interface STRING', '-i', String,
          'Local interface to hunt on'
        c.option '--prefix STRING', '-p', String,
          'Root to suggest for detected node names'
        c.option '--length INTEGER', '-l', Integer,
          'Numeric sequence length to use for suggested detected node names'
        c.option '--start INTEGER', '-s', Integer,
          'Start integer to use for suggested detected node names'
        c.action Commands::Hunter
      end

      command :dhcp do |c|
        c.syntax = 'metal dhcp [options]'
        c.summary = ''
        c.description = ''
        c.example 'description', 'command example'
        c.option '--template STRING', '-t', String, 'Specify dhcp template to use'
        c.action Commands::Dhcp
      end

      command :build do |c|
        c.syntax = 'metal build [options]'
        c.summary = ''
        c.description = ''
        c.example 'description', 'command example'
        c.option '--node STRING', '-n', String, 'Node name'
        c.option '--group STRING', '-g', String, 'Gender group'
        c.option '--kickstart STRING', '-k', String, 'Specify kickstart template to use'
        c.option '--pxelinux STRING', '-p', String, 'Specify pxelinux template to use'
        c.action Commands::Build
      end

      run!
    end
  end
end
