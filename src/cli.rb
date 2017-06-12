
# See http://stackoverflow.com/questions/837123/adding-a-directory-to-load-path-ruby.
$:.unshift File.dirname(__FILE__)

require 'rubygems'
require 'bundler/setup'
require 'commander'

require 'commander_extensions'
require 'commands'
require 'defaults'

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
        c.option '-t TEMPLATE', '--template TEMPLATE', String,
          "Specify hosts template to use (default: #{Defaults.hosts.template})"
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
          "Local interface to hunt on (default: #{Defaults.hunter.interface})"
        c.option '-p PREFIX', '--prefix PREFIX', String,
          "Root to suggest for detected node names (default: #{Defaults.hunter.prefix})"
        c.option '-l LENGTH', '--length LENGTH', Integer,
          "Numeric sequence length to use for suggested detected node names (default: #{Defaults.hunter.length})"
        c.option '-s START_NUMBER', '--start  START_NUMBER', Integer,
          "Start integer to use for suggested detected node names (default: #{Defaults.hunter.start})"
        c.action Commands::Hunter
      end

      command :dhcp do |c|
        c.syntax = 'metal dhcp [options]'
        c.summary = ''
        c.description = ''
        c.example 'description', 'command example'
        c.option '-t TEMPLATE', '--template TEMPLATE', String,
          "Specify dhcp template to use (default: #{Defaults.dhcp.template})"
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
          String, "Specify kickstart template to use (default: #{Defaults.build.kickstart})"
        c.option '-p PXELINUX_TEMPLATE', '--pxelinux  PXELINUX_TEMPLATE',
          String, "Specify pxelinux template to use (default: #{Defaults.build.pxelinux})"
        c.action Commands::Build
      end

      command :power do |c|
        c.syntax = 'metal power NODE_IDENTIFIER [COMMAND] [options]'
        c.summary = 'Volatile'
        c.description = ''
        c.option '-g', '--group', String,
          'Switch NODE_IDENTIFIER to specify a gender group rather than a single node'
        c.example 'description', 'command example'
        c.action Bash
      end

      command :console do |c|
        c.syntax = 'metal console NODE_IDENTIFIER [options]'
        c.summary = 'Volatile'
        c.description = ''
        c.example 'description', 'command example'
        c.action Bash
      end

      command :status do |c|
        c.syntax = 'metal status NODE_IDENTIFIER [options]'
        c.summary = 'Display the current network status of the nodes'
        c.description = "The status tool will attempt to determine the power and" \
                        " ping status of the node(s)."
        c.option '-g', '--group', String,
          'Switch NODE_IDENTIFIER to specify a gender group rather than a single node'
        c.option '--wait-limit', Integer,
          'Sets how long (in seconds) wait for a response from the node ' \
          'before assuming an error has occurred. Minimum 5 seconds. ' \
          "(default: #{Defaults.status.wait_limit})"
        c.option '--thread-limit', Integer,
          'Sets the maximum number of network operations' \
          "(default: #{Defaults.status.thread_limit})"
        c.action Commands::Status
      end

      def run!
        ARGV.push "--help" if ARGV.empty?
        super
      end

      run!
    end
  end
end
