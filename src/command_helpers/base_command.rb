# frozen_string_literal: true

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
require 'dependency'
require 'exceptions'
require 'dependency_specifications'
require 'validation/loader'
require 'file_path'
require 'namespaces/alces'

module Metalware
  module CommandHelpers
    class BaseCommand
      def initialize(args, options)
        pre_setup(args, options)
        setup
        post_setup
        run
      rescue Interrupt => e
        handle_interrupt(e)
      rescue IntentionallyCatchAnyException => e
        handle_fatal_exception(e)
      end

      private

      attr_reader :args, :options

      def pre_setup(args, options)
        setup_global_log_options(options)
        log_command
        @args = args
        @options = options
      end

      def post_setup
        enforce_dependency
      end

      def setup_global_log_options(options)
        MetalLog.strict = !!options.strict
        MetalLog.quiet = !!options.quiet
      end

      def dependency_specifications
        DependencySpecifications.new(alces)
      end

      def dependency_hash
        {}
      end

      def enforce_dependency
        Dependency.new(command_name, dependency_hash).enforce
      end

      def loader
        @loader ||= Validation::Loader.new
      end

      def file_path
        @file_path ||= FilePath
      end

      def command_name
        parts_without_namespace = \
          class_name_parts.slice(2, class_name_parts.length)
        parts_without_namespace.join(' ').to_sym
      end

      def class_name_parts
        self.class.name.split('::').map(&:downcase).map(&:to_sym)
      end

      def alces
        @alces ||= Namespaces::Alces.new
      end

      def log_command
        MetalLog.info "metal #{ARGV.join(' ')}"
      end

      # Setup can optionally be used to perform command-specific setup early on
      # in command execution.
      def setup; end

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
