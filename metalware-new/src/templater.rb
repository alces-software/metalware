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
# require "alces/stack/log"

module Metalware
  module Templater
    class Handler
      # XXX need `template_parameters` param? Child class, which is only one
      # used (outside of tests), forbids this.
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

      def initialize(hash={})
        repo = '/var/lib/metalware/repo'
        @combined_hash = DEFAULT_HASH.merge(hash)
        fixed_nodename = combined_hash[:nodename]
        @combined_hash.merge!(load_yaml_hash(repo))
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

      def file(filename, template={})
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
