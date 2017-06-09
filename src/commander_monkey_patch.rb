#==============================================================================
# Copyright (C) 2017 Stephen F. Norledge and Alces Software Ltd.
#
# This file/package is part of Alces Metalware.
#
# Alces Metalware is free software: you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License
# as published by the Free Software Foundation, either version 3 of
# the License, or (at your option) any later version.
#
# Alces Metalware is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this package.  If not, see <http://www.gnu.org/licenses/>.
#
# For more information on the Alces Metalware, please visit:
# https://github.com/alces-software/metalware
#==============================================================================

=begin
PATCH: Stops the global options polluting the short tag name-space

When a global option is created, Commander will automatically make a short tag
from the first letter (e.g. --strict also has -s) and thus pollutes the namespace

Secondly it does this silently without updating the CLI. Example, -s will trigger
the strict option but it will be listed by --help.

This patch removes the silent matching. It also removes the -t option from --trace
=end

module Commander
  class Runner
    # Removed the -t from --trace global option.
    # Does not prevent -t from triggering trace
    def run!
      trace = @always_trace || false
      require_program :version, :description
      trap('INT') { abort program(:int_message) } if program(:int_message)
      trap('INT') { program(:int_block).call } if program(:int_block)
      global_option('-h', '--help', 'Display help documentation') do
        args = @args - %w(-h --help)
        command(:help).run(*args)
        return
      end
      global_option('-v', '--version', 'Display version information') do
        say version
        return
      end
      # ORIGINALY: global_option('-t', '--trace', 'Display backtrace when an error occurs') { trace = true } unless @never_trace || @always_trace
      global_option('--trace', 'Display backtrace when an error occurs') { trace = true } unless @never_trace || @always_trace
      parse_global_options
      remove_global_options options, @args
      if trace
        run_active_command
      else
        begin
          run_active_command
        rescue InvalidCommandError => e
          abort "#{e}. Use --help for more information"
        rescue \
          OptionParser::InvalidOption,
          OptionParser::InvalidArgument,
          OptionParser::MissingArgument => e
          abort e.to_s
        rescue => e
          if @never_trace
            abort "error: #{e}."
          else
            abort "error: #{e}. Use --trace to view backtrace"
          end
        end
      end
    end

    # Prevents Commander from removing global options short tags from the input string
    def remove_global_options(options, args)
      # TODO: refactor with flipflop, please TJ ! have time to refactor me !
      options.each do |option|
        switches = option[:switches].dup
        next if switches.empty?

        if (switch_has_arg = switches.any? { |s| s =~ /[ =]/ })
          switches.map! { |s| s[0, s.index('=') || s.index(' ') || s.length] }
        end

        switches = expand_optionally_negative_switches(switches)

        past_switch, arg_removed = false, false
        args.delete_if do |arg|
          #ORIGINALY: if switches.any? { |s| s[0, arg.length] == arg }
          if switches.any? { |s| s == arg }
            arg_removed = !switch_has_arg
            past_switch = true
          elsif past_switch && !arg_removed && arg !~ /^-/
            arg_removed = true
          else
            arg_removed = true
            false
          end
        end
      end
    end
  end
end