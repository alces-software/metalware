
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

      command :'repo' do |c|
        c.syntax = 'metal repo [options]'
        c.summary = 'Manage template and config repository'
        c.sub_command_group = true
      end

      command :'repo use' do |c|
        c.syntax = 'metal repo use REPO_URL [options]'
        c.summary = 'Clone a new template git repo'
        c.description = 'Clones a new git repo from a URL. The repo should ' \
          'contain the default templates used by the other commands. It may ' \
          'also include a config directory containing template parameter YAML '\
          'files.'
        #c.example 'description', 'command example'
        c.option '-f', '--force',
          'Force use of a new repo even if local changes have been made to the current repo'
        c.sub_command = true
        c.action Commands::Repo::Use
      end

      command :'repo update' do |c|
        c.syntax = 'metal repo update [options]'
        c.summary = 'Updates the git repository'
        c.description = 'Updates the local git repository to match the remote.'\
          ' The update command does not support local changes. The force '\
          'will trigger a hard reset and will delete local changes. All other '\
          'git commands can be preformed manually on the repo.'
        #c.example 'description', 'command example'
        c.option '-f', '--force',
          'Force update even if local changes have been made to the repo'
        c.sub_command = true
        c.action Commands::Repo::Update
      end

      command :render do |c|
        c.syntax = 'metal render TEMPLATE [NODE] [options]'
        c.summary = 'Render a given template'
        c.description = 'Renders the file specified by TEMPLATE and sends the '\
          'output to standard out. The template can be rendered for a specific '\
          'node using the optional NODE input.'
        #c.example 'description', 'command example'
        c.action Commands::Render
      end

      command :hosts do |c|
        c.syntax = 'metal hosts NODE_IDENTIFIER [options]'
        c.summary = 'Adds a node(s) to the hosts file'
        c.description = 'Renders the hosts template for the node (or group) ' \
          'and appends it to /etc/hosts. Note that it does not check if the ' \
          'node already exists in the file.'
        #c.example 'description', 'command example'
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
        c.summary = 'Detects and caches DHCP discover messages'
        c.description = 'Hunter is used in conjunction with the dhcp command ' \
        'to update dhcp server. Hunter listens out for dhcp discovery ' \
        'messages from the booting nodes. Hunter assigns the nodes a node ' \
        'name based of PREFIX or user input. The node\'s name and ' \
        "MAC address is then cached.\n\nHunter will continue listening " \
        'for nodes until it is interrupted. A single MAC address will only be '\
        'cached once per run even if the compute node reboots. Refer to dhcp ' \
        'command to updated the dhcp server.'
        #c.example 'description', 'command example'
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
        c.summary = 'Renders and reboots dhcp from the hunter cache'
        c.description = 'Dhcp renders a template which is used to update the ' \
          'dhcp server. Dhcp is designed  to run after hunter and read from ' \
          'its cache. Hunter cache can be iterated over in the template with ' \
          '"alces.hunter.each". The rendered dhcp template is validated ' \
          'before the dhcp server is reset.'
        #c.example 'description', 'command example'
        c.option '-t TEMPLATE', '--template TEMPLATE', String,
          "Specify dhcp template to use (default: #{Defaults.dhcp.template})"
        c.action Commands::Dhcp
      end

      command :build do |c|
        c.syntax = 'metal build NODE_IDENTIFIER [options]'
        c.summary = 'Renders the templates used to build the nodes'
        c.description = 'Build is used to rendered template files before ' \
          'waiting for the compute nodes to pxe-boot and build. Build by ' \
          'default will render the pxelinux and kickstart templates. In ' \
          'additional, build renders the "files" list in [config].yaml for ' \
          "the gender group and node.\n\nBuild will then wait for the nodes " \
          'to build. Once a node has finished building, it needs to curl ' \
          '"alces.build_complete_url" which notifies build that the node is ' \
          'complete. This will trigger the pxelinux file to be re-rendered ' \
          'with "firstboot" set to false. Build will exit once all the nodes ' \
          'have finished building.'
        #c.example 'description', 'command example'
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
        c.summary = 'Volatile. Run power commands on a node.'
        c.description = 'Allows ipmi power commands to be ran on a node(s)' \
          "\n\nThe following commands are supported: " \
          "\non        - Turns the node on" \
          "\noff       - Turns the node off" \
          "\nstatus    - Display the power status" \
          "\nlocate    - Turns the node locater light on" \
          "\nlocateoff - Turns the node locater light off" \
          "\ncycle     - Power cycle the node" \
          "\nreset     - Warm reset the node"
        c.option '-g', '--group', String,
          'Switch NODE_IDENTIFIER to specify a gender group rather than a single node'
        #c.example 'description', 'command example'
        c.action BashCommand
      end

      command :console do |c|
        c.syntax = 'metal console NODE_IDENTIFIER [options]'
        c.summary = 'Volatile. Display a node\'s console in the terminal'
        c.description = 'Displays the console of a node in the terminal. The ' \
          'console command operates over the BMC network and can be used as ' \
          'node is booting.'
        #c.example 'description', 'command example'
        c.action BashCommand
      end

      command :status do |c|
        c.syntax = 'metal status NODE_IDENTIFIER [options]'
        c.summary = 'Display the current network status of the nodes'
        c.description = "The status tool will attempt to determine the power " \
                        "and ping status of the node(s)."
        c.option '-g', '--group', String,
          'Switch NODE_IDENTIFIER to specify a gender group rather than a single node'
        c.option '--wait-limit WAIT_LIMIT', Integer,
          'Sets how long (in seconds) wait for a response from the node ' \
          'before assuming an error has occurred. Minimum 1 seconds. ' \
          "(default: #{Defaults.status.wait_limit})"
        c.option '--thread-limit THREAD_LIMIT', Integer,
          'Sets the maximum number of network operations' \
          "(default: #{Defaults.status.thread_limit})"
        c.action Commands::Status
      end

      command :ipmi do |c|
        c.syntax = 'metal ipmi NODE_IDENTIFIER [options]'
        c.summary = 'Volatile. Perform ipmi commands on single or multiple machines'
        c.description = "***VOLATILE***\n\n" \
                    'Perform ipmi commands on single or multiple machines'
        #c.example 'description', 'command example'
        c.option '-g',
          'Specifies that NODE_IDENTIFIER is the group. MUST be before NODE_IDENTIFIER'
        c.option '-k COMMAND',
          'Specifies the ipmi command'
        c.action BashCommand
      end

      command :each do |c|
        c.syntax = 'metal each NODE_IDENTIFIER COMMAND [options]'
        c.summary = 'Runs a command for a node(s)'
        c.description = 'Runs the COMMAND for the node/ group specified by ' \
          'NODE_IDENTIFIER. Commands that contain spaces must be quoted. The ' \
          'command is first rendered by the templater and supports erb tags.'
        c.option '-g', '--group', String,
          'Switch NODE_IDENTIFIER to specify a gender group rather than a single node'
        c.action Commands::Each
      end

      def run!
        ARGV.push "--help" if ARGV.empty?
        super
      end

      run!
    end
  end
end
