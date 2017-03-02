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
      class Handler
        def file(filename, template_parameters={})
          File.open(filename.chomp, 'r') do |f|
            return replace_erb(f.read, template_parameters)
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

        def replace_erb(template, template_parameters={})
          return ERB.new(template).result(OpenStruct.new(template_parameters).instance_eval {binding})
        end

        def JSON_string_to_hash(json)
          return {} if !json or json.empty?
          return JSON.parse(json,:symbolize_names => true)
        end
      end

      class Combiner < Handler
        def initialize(json, hash={})
          @combined_hash = {hostip: `hostname -i`.chomp}
          @combined_hash.merge!(hash)
          @combined_hash.merge!(JSON_string_to_hash(json))
          @parsed_hash = parse_combined_hash
        end
        attr_reader :combined_hash
        attr_reader :parsed_hash

        def parse_combined_hash
          current_hash = Hash.new.merge(@combined_hash)
          current_str = current_hash.to_s
          old_str = ""
          count = 0
          while old_str != current_str
            count += 1
            raise LoopErbError if count > 10
            old_str = "#{current_str}"
            current_str = replace_erb(current_str, current_hash)
            current_hash = eval(current_str)
          end
          return current_hash
        end

        class LoopErbError < StandardError 
          def initialize(msg="Input hash may contains infinite recursive erb")
            super
          end
        end

        def file (filename, template={})
          raise HashInputError if !template.empty?
          super(filename, @parsed_hash)
        end

        class HashInputError < StandardError
          def initialize(msg="Hash included through file method. Must be included in Combiner initializer")
            super
          end
        end
      end

      class Finder
        def initialize(default_location)
          @default_location = default_location
        end
       
        def template=(new_template)
          @template = find_template(new_template)
          @filename_ext = @template.scan(/\.?[\w\_\-]+\.?[\w\_\-]*\Z/)[0].chomp
          @filename = @filename_ext.scan(/\.?[\w\_\-]+/)[0].chomp
        end

        attr_reader :template
        attr_reader :filename
        attr_reader :filename_ext

        def filename_diff_ext(ext)
          ext = ".#{ext}" if ext[0] != "."
          return "#{@filename}#{ext}"
        end

        def find_template(template)
          template = template.dup
          copy = "#{template}"
          template.gsub!(/\/\//,"/")
          template = "/" << template if template[0] != '/'
          template_erb = "#{template}.erb"
          # Checks if it's a full path to the default folder
          if template =~ /\A#{@default_location}.*\Z/
            return template if File.file?(template)
            return template_erb if File.file?(template_erb)
          end
          # Checks to see if the file is in the template folder
          path_template = "#{@default_location}#{template}"
          path_template.gsub!(/\/\//,"/")
          path_template_erb = "#{path_template}.erb"
          return path_template if File.file?(path_template)
          return path_template_erb if File.file?(path_template_erb)
          # Checks the file structure
          return template if File.file?(template)
          return template_erb if File.file?(template_erb)
          raise TemplateNotFound.new(copy)
        end

        class TemplateNotFound < StandardError
          def intialize(template)
            msg = "Could not find template file: " << template
            super
          end
        end
      end

      class Options
        def show_options(options={})
          options[:hostip] = "IP address of host node"
          # Flags
          none_flag = true
          print_json = false
          print_iterator = false
          puts
          puts "The following command line parameters are replaced by ERB:"
          options.each do |key, value|
            if key.to_s == 'JSON' and value.to_s == 'true'
              print_json = true
            elsif key.to_s == 'ITERATOR' and value.to_s == 'true'
              print_iterator = true
            else
              none_flag = false
              puts "    <%= #{key} %> : #{value}"
            end
          end
          puts "    (none)" if none_flag
          puts
          if print_iterator
            puts "When iterating over a node group, the following is replaced:"
            puts "    <%= nodename %> : The node name from the group"
            puts "    <%= index %> : The index in the group"
            puts "See ERB documentation for template algebra to use on 'index'"
            puts
          end
          if print_json
            puts "Include additional parameters in the JSON object. In the case of conflicts the priority order is: iterator parameters (if applicable), json inputs, then command line inputs"
            puts
          end
        end
      end
    end
  end
end