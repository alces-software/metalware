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

require 'metal_log'
require 'config'
require 'defaults'

module Metalware
  module Commands
    class BaseCommand
      def initialize(args, options)
        pre_setup(args, options)
        setup(args, options)
        run
      rescue Interrupt => e
        handle_interrupt(e)
      rescue Exception => e
        handle_fatal_exception(e)
      end

      attr_reader :config

      private

      def pre_setup(args, options)
        setup_config(options)
        setup_option_defaults(options)
        log_command
      end

      def setup_config(options)
        cli_options = {
          strict: !!options.strict,
          quiet: !!options.quiet
        }
        @config = Config.new(options.config, cli_options)
      end

      def setup_option_defaults(options)
        # TODO: this won't work correctly for subcommands as we will need to
        # specify defaults using more than just the command name; this does not
        # matter for now though since this only applies to `repo` currently and
        # no `repo` commands have defaults yet.
        command_defaults = Defaults.send(command_name)
        options.default(**command_defaults)
      end

      def command_name
        self.class.name.split('::')[-1].downcase
      end

      def log_command
        MetalLog.info "metal #{ARGV.join(" ")}"
      end

      def setup(args, options)
        raise NotImplementedError
      end

      def run
        raise NotImplementedError
      end

      def handle_interrupt(e)
        raise e
      end

      def handle_fatal_exception(e)
        MetalLog.fatal e.inspect
        raise e
      end
    end
  end
end
