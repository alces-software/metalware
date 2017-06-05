
# See http://stackoverflow.com/questions/837123/adding-a-directory-to-load-path-ruby.
$:.unshift File.dirname(__FILE__)

require 'rubygems'
require 'bundler/setup'
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

      global_option(
        '-c FILE', '--config FILE',
        'Specify config file to use instead of default (/opt/metalware/etc/config.yaml)'
      )

      global_option(
        '--strict', 'Convert warnings to errors'
      )

      global_option(
        '--quiet', 'Suppress any warnings from being displayed'
      )

      command :'repo use' do |c|
        c.syntax = 'metal repo use REPO_URL [options]'
        c.summary = ''
        c.description = ''
        c.example 'description', 'command example'
        c.option '-f', '--force',
          'Force use of a new repo even if local changes have been made to the current repo'
        c.action Commands::Repo::Use
      end

      command :'repo update' do |c|
        c.syntax = 'metal repo update [options]'
        c.summary = ''
        c.description = ''
        c.example 'description', 'command example'
        c.option '-f', '--force',
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
        c.syntax = 'metal hosts NODE_IDENTIFIER [options]'
        c.summary = ''
        c.description = ''
        c.example 'description', 'command example'
        c.option '-g', '--group', String,
          'Switch NODE_IDENTIFIER to specify a gender group rather than a single node'
        c.option '-t TEMPLATE', '--template TEMPLATE', String, 'Specify hosts template to use'
        c.option '-x', '--dry-run',
          'Do not modify hosts file, just output additions that would be made'
        c.action Commands::Hosts
      end

      command :hunter do |c|
        c.syntax = 'metal hunter [options]'
        c.summary = ''
        c.description = ''
        c.example 'description', 'command example'
        c.option '-i INTERFACE', '--interface INTERFACE', String,
          'Local interface to hunt on'
        c.option '-p PREFIX', '--prefix PREFIX', String,
          'Root to suggest for detected node names'
        c.option '-l LENGTH', '--length LENGTH', Integer,
          'Numeric sequence length to use for suggested detected node names'
        c.option '-s START_NUMBER', '--start  START_NUMBER', Integer,
          'Start integer to use for suggested detected node names'
        c.action Commands::Hunter
      end

      command :dhcp do |c|
        c.syntax = 'metal dhcp [options]'
        c.summary = ''
        c.description = ''
        c.example 'description', 'command example'
        c.option '-t TEMPLATE', '--template TEMPLATE', String, 'Specify dhcp template to use'
        c.action Commands::Dhcp
      end

      command :build do |c|
        c.syntax = 'metal build NODE_IDENTIFIER [options]'
        c.summary = ''
        c.description = ''
        c.example 'description', 'command example'
        c.option '-g', '--group', String,
          'Switch NODE_IDENTIFIER to specify a gender group rather than a single node'
        c.option '-k KICKSTART_TEMPLATE', '--kickstart KICKSTART_TEMPLATE',
          String, 'Specify kickstart template to use'
        c.option '-p PXELINUX_TEMPLATE', '--pxelinux  PXELINUX_TEMPLATE',
          String, 'Specify pxelinux template to use'
        c.action Commands::Build
      end

      command :power do |c|
        c.syntax = 'metal power NODE_IDENTIFIER [COMMAND] [options]'
        c.summary = 'Volatile'
        c.description = ''
        c.option '-g', '--group', String,
          'Switch NODE_IDENTIFIER to specify a gender group rather than a single node'
        c.example 'description', 'command example'
        c.action Commands::Bash
      end

      command :console do |c|
        c.syntax = 'metal console NODE_IDENTIFIER [options]'
        c.summary = 'Volatile'
        c.description = ''
        c.example 'description', 'command example'
        c.action Commands::Bash
      end

      def run!
        ARGV.push "--help" if ARGV.empty?
        super
      end

      run!
    end
  end
end
