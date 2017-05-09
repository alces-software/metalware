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
require "alces/stack/log"

module Metalware
  module Templater
    class << self
      def wrap(s, width)
        s.gsub(/(.{1,#{width}})(\s+|\Z)/, "\\1\n")
      end

      def putw(s)
        puts wrap(s, `tput cols`.to_i)
      end

      def show_options(options={})
        putw "Template input:"
        putw "Templates can be specifying by the full path to the file directly. " \
          "Alternatively, the template name can be specified and the default " \
          "path (see below) will be used instead. You do not need to include " \
          "the '.erb' file extension. Other extensions are accepted however " \
          "must be specified. A different repo can be specified by <repo>::" \
          "<filename> flag. In this case the repo path (see below) is used."
        puts
        putw "Default path : #{ENV['alces_REPO']}/templates/<action>/<filename>"
        putw "Repo path    : /var/lib/metalware/repos/<repo>/template/<action>/<filename>"
        puts
        putw "ERB Priority Order:"
        putw "ERB can replace template parameters with variables from 5 sources:"
        putw "  1) JSON input from the command line using -j"
        putw "  2) YAML config files stored in: #{ENV['alces_REPO']}/config"
        putw "  3) Command line inputs and index from the iterator (if applicable)"
        putw "  4) Constants available to all templates"
        puts
        putw "In the event of a conflict between the sources, the priority order" \
          " is as given above."
        putw "NOTE: nodename can not be overridden by JSON, YAML or ERB. This " \
          "is to because loading the YAML files is dependent on the nodename."
        puts
        putw "The templater uses the YAML files contained in the config directory " \
          "inside the repo (default or specified). The all.yaml config file " \
          "is loaded first followed by remaining config files according to " \
          "the reverse order defined in the genders file. Then " \
          "<nodename>.yaml is loaded last."
        puts
        putw "The following command line parameters are replaced by ERB:"
        none_flag = true
        if options.keys.max_by(&:length).nil? then option_length = 0
        else option_length = options.keys.max_by(&:length).length end
        const_length = Alces::Stack::Templater::Combiner::DEFAULT_HASH
          .keys.max_by(&:length).length
        if option_length > const_length then align = option_length
        else align = const_length end
        options.each do |key, value|
          none_flag = false;
          spaces = align - key.length
          str = "    <%= #{key} %> "
          while spaces > 0
            spaces -= 1
            str << " "
          end
          str << ": #{value}"
          putw str
        end
        putw "    (none)" if none_flag
        puts
        putw "The constant values replaced by erb:"
        Alces::Stack::Templater::Combiner::DEFAULT_HASH.each do |key, value|
          spaces = align - key.length
          str = "    <%= #{key} %> "
          while spaces > 0
            spaces -= 1
            str << " "
          end
          str << ": #{value} (#{value.class})"
          putw str
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
        Alces::Stack::Log.info "Template Saved: #{save_file}"
      end

      def append(template_file, append_file, template_parameters={})
        File.open(append_file.chomp, 'a') do |f|
          f.puts file(template_file, template_parameters)
        end
        Alces::Stack::Log.info "Template Appended: #{append_file}"
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
      def self.hostip
        determine_hostip_script = '/opt/metalware/libexec/determine-hostip'

        hostip = `#{determine_hostip_script}`.chomp
        if $?.success?
          hostip
        else
          # If script failed for any reason fall back to using `hostname -i`,
          # which may or may not give the IP on the interface we actually
          # want to use (note: the dance with pipes is so we only get the
          # last word in the output, as I've had the IPv6 IP included first
          # before, which breaks all the things).
          `hostname -i | xargs -d' ' -n1 | tail -n 2 | head -n 1`.chomp
        end
      end

      DEFAULT_HASH = {
        hostip: self.hostip,
        index: 0,
        permanent_boot: false
      }

      def initialize(repo, json, hash={})
        repo = set_repo(repo)
        @combined_hash = DEFAULT_HASH.merge(hash)
        fixed_nodename = combined_hash[:nodename]
        @combined_hash.merge!(load_yaml_hash(repo))
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

      def set_repo(repo)
        repo = nil if repo.to_s.empty?
        repo ||= lambda {
          Alces::Stack::Log.warn "Alces::Stack::Templater::Combiner Implicitly using default repo"
          "#{ENV['alces_REPO']}"
        }.call
      end

      def load_json_hash(json)
        (json || "").empty? ? {} : JSON.parse(json,symbolize_names: true)
      end

      def load_yaml_hash(repo)
        hash = Hash.new
        get_yaml_file_list.each do |yaml|
          begin
            yaml_payload = YAML.load(File.read("#{repo}/config/#{yaml}.yaml"))
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
        list = [ "all" ]
        return list if !@combined_hash.key?(:nodename)
        list_str = `nodeattr -l #{@combined_hash[:nodename]} 2>/dev/null`.chomp
        if list_str.empty? then return list end
        list.concat(list_str.split(/\n/).reverse)
        list.push(@combined_hash[:nodename])
        list.uniq
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
  end
end
