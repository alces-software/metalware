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
            return replace_hash(f.read, 0, template_parameters)
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

        def replace_hash(template, count, template_parameters={})
          raise "Templater loop count reached. Check parameters for infinite loops" if count > 100
          tags = template.scan(/<%=[ \w\*\+\-\/\%\(\)\=\!]*%>/)
          return template if tags.length == 0
          error_tag = false
          error_message  = "Could not find value(s) for:"
          tags.each do |t|
            t.scan(/_*[[:alpha:]][[:alnum:]_]*/) do |word|
              if !template_parameters.has_key?(word.to_sym)
                error_tag = true
                error_message << "\n  " << t
                break
              end
            end
          end
          raise error_message if error_tag
          return replace_hash(ERB.new(template).result(OpenStruct.new(template_parameters).instance_eval {binding}), count + 1, template_parameters)
        end

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
      
      class JSON_Templater
        class << self
          def file(filename, json, template_parameters={})
            Alces::Stack::Templater.file(filename, parse(json, template_parameters))
          end

          def save(filename, save_file, json, template_parameters={})
            Alces::Stack::Templater.save(filename, save_file, parse(json, template_parameters))
          end

          def append(filename, append_file, json, template_parameters={})
            Alces::Stack::Templater.append(filename, append_file, parse(json, template_parameters))
          end

          def parse(json, template_parameters={})
            template_parameters = add_default_parameters(template_parameters)
            # Skips if json is empty
            return template_parameters if json.to_s.strip.empty? or !json
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

          def add_default_parameters(template_parameters={})
            template_parameters[:hostip] = `hostname -i`.chomp if !template_parameters.key?(:hostip)
            return template_parameters
          end
        end
      end

      class Finder
        def initialize(default_location)
          @default_location = default_location
        end

        def get_default
          return @default_location
        end

        def find(template)
          copy = template
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
          raise "Could not find template file: " << copy
        end
      end
    end
  end
end