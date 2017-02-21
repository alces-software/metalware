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
require "erb"
require "ostruct"
require "json"

module Alces
  module Stack
    module Templater
      class << self
        def file(filename, template_parameters={})
          File.open(filename.chomp, 'r') do |f|
            return replace_hash(f.read, template_parameters)
          end
        end

        def save(template_file, save_file, template_parameters={})
          File.open(save_file.chomp, "w") do |f|
            f.puts file(template_file, template_parameters)
          end
        end

        def append(template_file, append_file, template_parameters={})
          File.open(append_file.chomp, 'a') do |f|
            f.puts file(template_file, template_parameters)
          end
        end

        def file_json(filename, json, template_parameters={})
          file(filename, parse_json(json, template_parameters))
        end

        def save_json(filename, save_file, json, template_parameters={})
          save(filename, save_file, parse_json(json, template_parameters))
        end

        def append_json(filename, append_file, json, template_parameters={})
          append(filename, append_file, parse_json(json, template_parameters))
        end

        def parse_json(json, template_parameters={})
          # Loads content if json is a file
          if File.file?(json)
            json = File.read(json)
          elsif /\A(\/?\w)*(.\w*)?\Z/ =~ json
            raise "Could not find file: " << json
          end
          #Extracts the JSON data
          begin
            JSON.load(json).each do |key, value|
              template_parameters[key.to_sym] = value
            end
          rescue => e
            STDERR.puts "ERROR: Could not pass JSON object, insure keys are also strings"
            raise e
          end
          #Returns the hash
          return template_parameters
        end

        def replace_hash(template, template_parameters={})
          return ERB.new(template).result(OpenStruct.new(template_parameters).instance_eval {binding})
        end

        def show_options(options={})
          puts "The following parameters are replaced by ERB:"
          print_json = false
          options.each do |key, value|
            if key.to_s == 'JSON' and value.to_s == 'true'
              print_json = true
            else
              puts "    <%= #{key} %> : #{value}"
            end
          end
          puts "Include additional parameters in the JSON object. In the case of conflicts, the JSON value is used" if print_json
          puts
        end
      end
    end
  end
end