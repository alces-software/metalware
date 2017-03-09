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
require "yaml"

module Alces
  module Stack
    module Templater
      class << self
        def show_options(options={})
          const = {
            hostip: "#{`hostname -i`.chomp}",
            index: "0 (integer)",
            permanentboot: "false (boolean)"
          }
          puts "ERB can replace template parameters with variables from 5 sources:"
          puts "  1) JSON input from the command line using -j"
          puts "  2) YAML config files stored in: #{ENV['alces_BASE']}/etc/config"
          puts "  3) Command line inputs and index from the iterator (if applicable)"
          puts "  4) Constants available to all templates"
          puts
          puts "In the event of a conflict between the sources, the priority order is as given above."
          puts "NOTE: nodename can not be overridden by JSON, YAML or ERB. This is to because loading the YAML files is dependent on the nodename."
          puts
          puts "The yaml config files are stored in #{ENV['alces_BASE']}/etc/config"
          puts "The config files are loaded according to the reverse order defined in the genders folder, with <nodename>.yaml being loaded last."
          puts
          puts "The following command line parameters are replaced by ERB:"
          none_flag = true
          if options.keys.max_by(&:length).nil? then option_length = 0
          else option_length = options.keys.max_by(&:length).length end
          const_length = const.keys.max_by(&:length).length
          if option_length > const_length then align = option_length
          else align = const_length end
          options.each do |key, value|
            none_flag = false;
            spaces = align - key.length
            print"    <%= #{key} %> "
            while spaces > 0
              spaces -= 1
              print " "
            end
            puts ": #{value}"
          end
          puts "    (none)" if none_flag
          puts
          puts "The constant values replaced by erb:"
          const.each do |key, value|
            spaces = align - key.length
            print"    <%= #{key} %> "
            while spaces > 0
              spaces -= 1
              print " "
            end
            puts ": #{value}"
          end
        end
      end

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
        rescue StandardError => e
          $stderr.puts "Could not parse ERB"
          $stderr.puts template.to_s
          $stderr.puts template_parameters.to_s
          raise e
        end
      end

      class Combiner < Handler
        DEFAULT_HASH = {
            hostip: `hostname -i`.chomp,
            index: 0,
            permanentboot: false
          }
        def initialize(json, hash={})
          @combined_hash = DEFAULT_HASH.merge(hash)
          fixed_nodename = combined_hash[:nodename]
          @combined_hash.merge!(load_yaml_hash)
          @combined_hash.merge!(load_json_hash(json))
          @parsed_hash = parse_combined_hash
          if parsed_hash[:nodename] != fixed_nodename
            raise HashOverrideError.new(fixed_nodename, @parsed_hash)
          end
        end
        class HashOverrideError < StandardError
          def initialize(nodename, index, parsed_hash={})
            msg = "Original nodename: " << nodename.to_s << "\n"
            msg << parsed_hash.to_s << "\n"
            msg << "YAML, JSON and ERB can not alter the values of nodename and index"
            super(msg)
          end
        end

        attr_reader :combined_hash
        attr_reader :parsed_hash

        def load_json_hash(json)
          (json || "").empty? ? {} : JSON.parse(json,symbolize_names: true)
        end

        def load_yaml_hash()
          hash = Hash.new
          get_yaml_file_list.each do |yaml|
            begin 
              yaml_payload = YAML.load(File.read("#{ENV['alces_BASE']}/etc/config/#{yaml}.yaml"))
            rescue Errno::ENOENT # Skips missing files
            rescue StandardError => e
              $stderr.puts "Could not pass YAML file"
              raise e
            else
              if !yaml_payload.is_a? Hash
                raise "Expected yaml config to contain a hash" 
              else
                hash.merge!(yaml_payload)
              end
            end
          end
          hash.inject({}) do |memo,(k,v)| memo[k.to_sym] = v; memo end
        end

        def get_yaml_file_list
          return Array.new if !@combined_hash.key?(:nodename)
          list_str = `nodeattr -l #{@combined_hash[:nodename]} 2>/dev/null`.chomp
          if list_str.empty? then return Array.new end
          list = list_str.split(/\n/).reverse
          return list << @combined_hash[:nodename]
        end

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
        def initialize(default_location, template)
          @default_location = default_location
          @template = find_template(template)
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
          begin
            template = template.dup
          rescue StandardError
            raise TemplateNotFound.new(template)
          end
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
    end
  end
end