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
require 'yaml'

require 'commands'
require 'cli_helper/dynamic_defaults'

module Metalware
  module CliHelper
    CONFIG_PATH = File.join(File.dirname(__FILE__), 'config.yaml')

    class Parser
      def initialize(calling_obj = nil)
        @calling_obj = calling_obj

        # NOTE: Now that Metalware has a `Data` module the majority of yaml
        # handling occurs through that.
        # CliHelper and autocomplete are exceptions as they should only ever be
        # altered by developers and need to load the file as is, instead of
        # Metalware altering it to what it thinks it needs to be.
        @yaml = YAML.load_file(CONFIG_PATH)
      end

      def parse_commands
        @yaml['commands'].each do |command, attributes|
          parse_command_attributes(command, attributes)
        end
        @yaml['global_options'].each do |opt|
          @calling_obj.global_option(*opt['tags'], opt['description'].chomp)
        end
      end

      private

      # TODO: Currently the parser does not support the example option
      def parse_command_attributes(command, attributes)
        @calling_obj.command command do |c|
          attributes.each do |a, v|
            next if a == 'autocomplete'
            case a
            when 'action'
              c.action eval(v)
            when 'options'
              v.each do |opt|
                if [:Integer, 'Integer'].include? opt['type']
                  opt['type'] = 'OptionParser::DecimalInteger'
                end
                c.option(*opt['tags'],
                         eval(opt['type'].to_s),
                         { default: parse_default(opt) },
                         (opt['description']).to_s.chomp)
              end
            when 'subcommands'
              c.sub_command_group = true
              v.each do |subcommand, subattributes|
                subattributes[:sub_command] = true
                subcommand = "#{command} #{subcommand}"
                parse_command_attributes(subcommand, subattributes)
              end
            else
              c.send("#{a}=", v.respond_to?(:chomp) ? v.chomp : v)
            end
          end
        end
      end

      def parse_default(opt)
        default_value = opt['default']
        if default_value.is_a? Hash
          dynamic_default_method = default_value['dynamic']
          DynamicDefaults.send(dynamic_default_method)
        else
          default_value
        end
      end
    end
  end
end
