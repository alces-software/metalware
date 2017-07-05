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

module Metalware
  module CliHelper
    class Parser
      def initialize(calling_obj = nil)
        @calling_obj = calling_obj
        config = File.join(File.dirname(__FILE__), "config.yaml")
        @yaml = YAML.load_file(config)
      end

      def parse_commands
        @yaml["commands"].each do |command, attributes|
          parse_command_attributes(command, attributes)
        end
        @yaml["global_options"].each do |opt|
          @calling_obj.global_option(*opt["tags"], opt["description"].chomp)
        end
      end

      # TODO: Currently the parser does not support the example option
      def parse_command_attributes(command, attributes)
        @calling_obj.command command do |c|
          attributes.each do |a, v|
            case a
            when "action"
              c.action eval(v)
            when "options"
              v.each do |opt|
                if [:Integer, "Integer"].include? opt["type"]
                  opt["type"] = "OptionParser::DecimalInteger"
                end
                c.option(*opt["tags"],
                       eval(opt["type"].to_s),
                       {default: opt["default"]},
                       "#{opt["description"]}".chomp)
              end
            when "subcommands"
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
    end
  end
end
